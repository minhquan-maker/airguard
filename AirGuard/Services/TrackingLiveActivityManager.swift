//
//  TrackingLiveActivityManager.swift
//  AirGuard
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@MainActor
final class TrackingLiveActivityManager {
    static let shared = TrackingLiveActivityManager()

    private var activity: Activity<TrackingActivityAttributes>?

    private init() {}

    func start(vehicleName: String, startedAt: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if activity != nil { return }

        let attrs = TrackingActivityAttributes(title: "AirGuard Tracking")
        let state = TrackingActivityAttributes.ContentState(
            vehicleName: vehicleName,
            distanceKm: 0,
            startedAt: startedAt,
            isTracking: true
        )

        do {
            activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Silently ignore to avoid blocking trip tracking.
        }
    }

    func update(vehicleName: String, distanceKm: Double, startedAt: Date) async {
        guard let activity else { return }
        let state = TrackingActivityAttributes.ContentState(
            vehicleName: vehicleName,
            distanceKm: distanceKm,
            startedAt: startedAt,
            isTracking: true
        )
        await activity.update(.init(state: state, staleDate: nil))
    }

    func end(finalDistanceKm: Double, vehicleName: String, startedAt: Date) async {
        guard let activity else { return }
        let endState = TrackingActivityAttributes.ContentState(
            vehicleName: vehicleName,
            distanceKm: finalDistanceKm,
            startedAt: startedAt,
            isTracking: false
        )
        await activity.end(
            .init(state: endState, staleDate: nil),
            dismissalPolicy: .immediate
        )
        self.activity = nil
    }
}
#endif
