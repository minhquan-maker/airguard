//
//  MotionAutoTripTracker.swift
//  AirGuard
//
//  Trip detection: Core Motion (.automotive, including low confidence) + GPS speed fallback
//  (motorbikes often never report .automotive). Distance from Core Location while in-trip.
//

import CoreLocation
import CoreMotion
import Foundation
import Observation

private enum TripSessionSource: Equatable {
    case none
    case motionAutomotive
    case gpsSpeed
    case manual
}

@Observable
final class MotionAutoTripTracker: NSObject {
    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()

    private weak var tripStore: TripStore?
    private weak var profileStore: UserProfileStore?

    private(set) var motionActivityAvailable: Bool = CMMotionActivityManager.isActivityAvailable()
    private(set) var isSessionActive: Bool = false
    private(set) var sessionDistanceMeters: Double = 0

    /// True when the user started the current session from the manual GPS control (not motion/speed auto-start).
    private(set) var isManualTripSession: Bool = false

    private var motionUpdatesRunning = false
    private var sessionSource: TripSessionSource = .none

    private var automotiveCandidateSince: Date?
    private var notAutomotiveSince: Date?
    private var speedTripCandidateSince: Date?
    private var lastTripMovementAt: Date?

    private var lastLocation: CLLocation?
    private var sessionStartedAt: Date?
    private var sessionRoutePoints: [TripRoutePoint] = []
    #if DEBUG
    private var debugSimulationTimer: DispatchSourceTimer?
    private(set) var isDebugSimulationActive: Bool = false
    #endif

    private let automotiveHoldSeconds: TimeInterval = 12
    private let automotiveReleaseSeconds: TimeInterval = 45
    private let speedHoldSeconds: TimeInterval = 12
    private let speedStartMinMps: Double = 2.2
    private let minimumTripMeters: Double = 150
    private let maxHorizontalAccuracyMeters: CLLocationAccuracy = 80

    private var supportsBackgroundLocationMode: Bool {
        guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }
        return modes.contains("location")
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false
        applyLocationConfiguration(listening: true)
    }

    func bind(tripStore: TripStore, profileStore: UserProfileStore) {
        self.tripStore = tripStore
        self.profileStore = profileStore
    }

    /// Call when profile, permissions, or app lifecycle may require a refresh.
    func applyPolicyFromProfile() {
        guard let profileStore else { return }
        guard profileStore.profile.hasCompletedWelcome else {
            stopAll()
            return
        }

        let auto = profileStore.profile.autoMotionTrackingEnabled

        if !auto {
            stopMotionUpdates()
            speedTripCandidateSince = nil
            automotiveCandidateSince = nil
            notAutomotiveSince = nil
            if !isSessionActive {
                stopLocationUpdatesCompletely()
            } else if sessionSource == .manual {
                applyLocationConfiguration(listening: false)
                if !locationManagerIsUpdating {
                    locationManager.startUpdatingLocation()
                    locationManagerIsUpdating = true
                }
            } else {
                endSessionDiscardLocation()
            }
            syncManualSessionFlag()
            return
        }

        // Auto pipeline: motion when available + GPS listening for speed-based starts.
        if motionActivityAvailable {
            let motionAuth = CMMotionActivityManager.authorizationStatus()
            if motionAuth == .notDetermined {
                ensureListeningLocationForAuto()
                motionManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, _ in
                    DispatchQueue.main.async {
                        self.requestLocationAuthorizationIfNeeded()
                        self.startMotionUpdatesIfNeeded()
                        self.ensureListeningLocationForAuto()
                    }
                }
                return
            }
            if motionAuth == .authorized {
                requestLocationAuthorizationIfNeeded()
                startMotionUpdatesIfNeeded()
            }
        } else {
            requestLocationAuthorizationIfNeeded()
        }

        ensureListeningLocationForAuto()
        syncManualSessionFlag()
    }

    /// Starts a real GPS trip without waiting for motion. Ends only via ``stopManualGpsTrip(save:)`` (no motion-based auto-end).
    func startManualGpsTrip() {
        guard isSessionActive == false else { return }
        #if DEBUG
        guard isDebugSimulationActive == false else { return }
        #endif
        guard profileStore?.profile.hasCompletedWelcome == true else { return }

        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            requestLocationAuthorizationIfNeeded()
            return
        }

        requestLocationAuthorizationIfNeeded()
        beginSession(source: .manual)
    }

    /// Ends a manual GPS trip. When `save` is true, persists if distance meets the minimum trip threshold (same as auto).
    func stopManualGpsTrip(save: Bool) {
        guard sessionSource == .manual else { return }
        if save {
            endSessionAndSaveIfNeeded()
        } else {
            endSessionDiscardLocation()
        }
    }

    func stopAll() {
        #if DEBUG
        stopDebugTripSimulation(discardWithoutSaving: true)
        #endif
        stopMotionUpdates()
        endSessionDiscardLocation()
        automotiveCandidateSince = nil
        notAutomotiveSince = nil
        speedTripCandidateSince = nil
        lastTripMovementAt = nil
        sessionSource = .none
        syncManualSessionFlag()
    }

    private var locationManagerIsUpdating = false

    private func applyLocationConfiguration(listening: Bool) {
        if listening {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 35
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 20
        }
    }

    private func ensureListeningLocationForAuto() {
        guard profileStore?.profile.autoMotionTrackingEnabled == true else { return }
        guard isSessionActive == false else { return }
        #if DEBUG
        guard isDebugSimulationActive == false else { return }
        #endif
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }

        applyLocationConfiguration(listening: true)
        if !locationManagerIsUpdating {
            locationManager.startUpdatingLocation()
            locationManagerIsUpdating = true
        }
    }

    private func stopLocationUpdatesCompletely() {
        locationManager.stopUpdatingLocation()
        locationManagerIsUpdating = false
    }

    private func syncManualSessionFlag() {
        isManualTripSession = (sessionSource == .manual)
    }

    // MARK: - Motion

    private func startMotionUpdatesIfNeeded() {
        guard motionActivityAvailable else { return }
        guard CMMotionActivityManager.authorizationStatus() == .authorized else { return }
        guard motionUpdatesRunning == false else { return }
        motionUpdatesRunning = true
        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            self?.handle(activity: activity)
        }
    }

    private func stopMotionUpdates() {
        guard motionUpdatesRunning else { return }
        motionManager.stopActivityUpdates()
        motionUpdatesRunning = false
    }

    private func handle(activity: CMMotionActivity?) {
        guard let activity else { return }
        #if DEBUG
        guard isDebugSimulationActive == false else { return }
        #endif
        guard profileStore?.profile.autoMotionTrackingEnabled == true else { return }

        // Motorbikes often report .automotive with .low confidence — still treat as driving candidate.
        let automotiveHint = activity.automotive

        if automotiveHint {
            notAutomotiveSince = nil
            if automotiveCandidateSince == nil {
                automotiveCandidateSince = Date()
            } else if let start = automotiveCandidateSince,
                      Date().timeIntervalSince(start) >= automotiveHoldSeconds
            {
                if !isSessionActive {
                    beginSession(source: .motionAutomotive)
                }
            }
        } else {
            automotiveCandidateSince = nil
            if isSessionActive, sessionSource != .manual {
                if notAutomotiveSince == nil {
                    notAutomotiveSince = Date()
                } else if let end = notAutomotiveSince,
                          Date().timeIntervalSince(end) >= automotiveReleaseSeconds
                {
                    endSessionAndSaveIfNeeded()
                    notAutomotiveSince = nil
                }
            } else if !isSessionActive {
                notAutomotiveSince = nil
            }
        }
    }

    // MARK: - Session

    private func beginSession(source: TripSessionSource) {
        guard isSessionActive == false else { return }
        sessionSource = source
        syncManualSessionFlag()
        isSessionActive = true
        sessionDistanceMeters = 0
        sessionStartedAt = .now
        sessionRoutePoints.removeAll()
        lastLocation = nil
        lastTripMovementAt = .now
        notAutomotiveSince = nil
        speedTripCandidateSince = nil
        automotiveCandidateSince = nil

        requestLocationAuthorizationIfNeeded()
        applyLocationConfiguration(listening: false)
        if !locationManagerIsUpdating {
            locationManager.startUpdatingLocation()
            locationManagerIsUpdating = true
        } else {
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
            locationManagerIsUpdating = true
        }
        startLiveActivity()
    }

    private func endSessionDiscardLocation() {
        locationManager.stopUpdatingLocation()
        locationManagerIsUpdating = false
        endLiveActivity(finalDistanceMeters: sessionDistanceMeters)
        lastLocation = nil
        isSessionActive = false
        sessionDistanceMeters = 0
        sessionStartedAt = nil
        sessionSource = .none
        syncManualSessionFlag()
        lastTripMovementAt = nil
        notAutomotiveSince = nil
        speedTripCandidateSince = nil
        automotiveCandidateSince = nil
        sessionRoutePoints.removeAll()

        if profileStore?.profile.autoMotionTrackingEnabled == true {
            ensureListeningLocationForAuto()
        }
    }

    private func endSessionAndSaveIfNeeded() {
        let capturedRoute = sessionRoutePoints
        let capturedStart = sessionStartedAt

        locationManager.stopUpdatingLocation()
        locationManagerIsUpdating = false
        let meters = sessionDistanceMeters
        endLiveActivity(finalDistanceMeters: meters)
        lastLocation = nil
        isSessionActive = false
        sessionDistanceMeters = 0
        sessionStartedAt = nil
        sessionSource = .none
        syncManualSessionFlag()
        lastTripMovementAt = nil
        notAutomotiveSince = nil
        speedTripCandidateSince = nil
        automotiveCandidateSince = nil
        sessionRoutePoints.removeAll()

        let durationSeconds = capturedStart.map { Date().timeIntervalSince($0) }
        let routeForTrip: [TripRoutePoint]? = capturedRoute.isEmpty ? nil : capturedRoute

        guard meters >= minimumTripMeters else {
            if profileStore?.profile.autoMotionTrackingEnabled == true {
                ensureListeningLocationForAuto()
            }
            return
        }
        guard let tripStore = self.tripStore, let profileStore = self.profileStore else {
            if self.profileStore?.profile.autoMotionTrackingEnabled == true {
                ensureListeningLocationForAuto()
            }
            return
        }

        let km = (meters / 1000.0 * 100).rounded() / 100
        let vehicle = profileStore.profile.defaultAutoVehicleKind
        let co2 = EmissionEngine.tripCO2Kg(distanceKm: km, vehicle: vehicle)
        let trip = TripEntry(
            distanceKm: km,
            vehicle: vehicle,
            co2Kg: co2,
            durationSeconds: durationSeconds,
            routePoints: routeForTrip
        )
        tripStore.add(trip)

        if profileStore.profile.autoMotionTrackingEnabled {
            ensureListeningLocationForAuto()
        }
    }

    private func recordRouteSample(_ loc: CLLocation) {
        let p = TripRoutePoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        if sessionRoutePoints.isEmpty {
            sessionRoutePoints.append(p)
            return
        }
        if let last = sessionRoutePoints.last {
            let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let gap = loc.distance(from: lastLoc)
            if gap >= 12 {
                sessionRoutePoints.append(p)
                if sessionRoutePoints.count > 600 {
                    sessionRoutePoints.removeFirst(sessionRoutePoints.count - 400)
                }
            }
        }
    }

    private func registerTripMovement() {
        lastTripMovementAt = Date()
        if sessionSource != .manual {
            notAutomotiveSince = nil
        }
    }

    private func trySpeedBasedTripStart(location loc: CLLocation) {
        guard profileStore?.profile.autoMotionTrackingEnabled == true else { return }
        guard isSessionActive == false else { return }
        #if DEBUG
        guard isDebugSimulationActive == false else { return }
        #endif
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= maxHorizontalAccuracyMeters else {
            speedTripCandidateSince = nil
            return
        }

        let spd = loc.speed
        let now = Date()
        if spd >= 0, spd >= speedStartMinMps {
            if speedTripCandidateSince == nil {
                speedTripCandidateSince = now
            } else if let t = speedTripCandidateSince, now.timeIntervalSince(t) >= speedHoldSeconds {
                beginSession(source: .gpsSpeed)
                speedTripCandidateSince = nil
            }
        } else {
            speedTripCandidateSince = nil
        }
    }

    private func checkStaleTripEnd() {
        guard isSessionActive else { return }
        #if DEBUG
        guard isDebugSimulationActive == false else { return }
        #endif
        guard sessionSource != .manual else { return }
        guard let lastMove = lastTripMovementAt else { return }
        guard Date().timeIntervalSince(lastMove) >= automotiveReleaseSeconds else { return }
        endSessionAndSaveIfNeeded()
    }

    #if DEBUG
    // MARK: - Debug simulation

    func startDebugTripSimulation() {
        guard isDebugSimulationActive == false else { return }
        guard isSessionActive == false else { return }
        guard profileStore != nil else { return }

        isDebugSimulationActive = true
        sessionSource = .none
        syncManualSessionFlag()
        isSessionActive = true
        sessionDistanceMeters = 0
        sessionStartedAt = .now
        sessionRoutePoints.removeAll()
        lastLocation = nil
        lastTripMovementAt = .now
        startLiveActivity()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.isDebugSimulationActive else { return }
            self.sessionDistanceMeters += 80
            self.updateLiveActivityDistance()
        }
        debugSimulationTimer = timer
        timer.resume()
    }

    func stopDebugTripSimulation(discardWithoutSaving: Bool = false) {
        guard isDebugSimulationActive else { return }
        debugSimulationTimer?.cancel()
        debugSimulationTimer = nil
        isDebugSimulationActive = false

        let meters = sessionDistanceMeters
        endLiveActivity(finalDistanceMeters: meters)

        guard discardWithoutSaving == false else {
            isSessionActive = false
            sessionDistanceMeters = 0
            sessionStartedAt = nil
            sessionSource = .none
            syncManualSessionFlag()
            lastTripMovementAt = nil
            if profileStore?.profile.autoMotionTrackingEnabled == true {
                ensureListeningLocationForAuto()
            }
            return
        }

        guard let tripStore = self.tripStore, let profileStore = self.profileStore else {
            isSessionActive = false
            sessionDistanceMeters = 0
            sessionStartedAt = nil
            sessionSource = .none
            syncManualSessionFlag()
            return
        }
        let km = (meters / 1000.0 * 100).rounded() / 100
        let vehicle = profileStore.profile.defaultAutoVehicleKind
        let co2 = EmissionEngine.tripCO2Kg(distanceKm: km, vehicle: vehicle)
        let durationSeconds = sessionStartedAt.map { Date().timeIntervalSince($0) }
        let trip = TripEntry(
            distanceKm: km,
            vehicle: vehicle,
            co2Kg: co2,
            durationSeconds: durationSeconds,
            routePoints: nil
        )
        tripStore.add(trip)

        isSessionActive = false
        sessionDistanceMeters = 0
        sessionStartedAt = nil
        sessionSource = .none
        syncManualSessionFlag()
        lastTripMovementAt = nil
        if profileStore.profile.autoMotionTrackingEnabled {
            ensureListeningLocationForAuto()
        }
    }
    #endif

    // MARK: - Live Activity

    private func startLiveActivity() {
#if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard let profileStore else { return }
        let vehicleName = profileStore.profile.defaultAutoVehicleKind.title
        let startedAt = sessionStartedAt ?? .now
        Task { @MainActor in
            TrackingLiveActivityManager.shared.start(
                vehicleName: vehicleName,
                startedAt: startedAt
            )
        }
#endif
    }

    private func updateLiveActivityDistance() {
#if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard let profileStore else { return }
        let km = sessionDistanceMeters / 1000
        let vehicleName = profileStore.profile.defaultAutoVehicleKind.title
        let started = sessionStartedAt ?? .now
        Task { @MainActor in
            await TrackingLiveActivityManager.shared.update(
                vehicleName: vehicleName,
                distanceKm: km,
                startedAt: started
            )
        }
#endif
    }

    private func endLiveActivity(finalDistanceMeters: Double) {
#if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard let profileStore else { return }
        let km = finalDistanceMeters / 1000
        let vehicleName = profileStore.profile.defaultAutoVehicleKind.title
        let started = sessionStartedAt ?? .now
        Task { @MainActor in
            await TrackingLiveActivityManager.shared.end(
                finalDistanceKm: km,
                vehicleName: vehicleName,
                startedAt: started
            )
        }
#endif
    }

    // MARK: - Location permission

    private func requestLocationAuthorizationIfNeeded() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            break
        default:
            break
        }
        updateBackgroundLocationCapability()
    }

    private func updateBackgroundLocationCapability() {
        let canRunInBackground = supportsBackgroundLocationMode && locationManager.authorizationStatus == .authorizedAlways
        locationManager.allowsBackgroundLocationUpdates = canRunInBackground
    }
}

extension MotionAutoTripTracker: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateBackgroundLocationCapability()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            applyPolicyFromProfile()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= maxHorizontalAccuracyMeters else { return }

        if isSessionActive {
            #if DEBUG
            if isDebugSimulationActive { return }
            #endif

            var moved = false
            if let last = lastLocation {
                let delta = loc.distance(from: last)
                if delta > 0, delta < 5000 {
                    sessionDistanceMeters += delta
                    moved = delta >= 8
                    updateLiveActivityDistance()
                }
            }
            lastLocation = loc

            let spd = loc.speed
            if spd >= 0, spd >= 1.4 { moved = true }
            if moved { registerTripMovement() }

            recordRouteSample(loc)

            checkStaleTripEnd()
            return
        }

        trySpeedBasedTripStart(location: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _ = error
    }
}
