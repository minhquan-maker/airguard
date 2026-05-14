//
//  TripEntry.swift
//  AirGuard
//

import Foundation

/// A single GPS sample along a tracked trip (WGS84).
struct TripRoutePoint: Codable, Equatable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
}

struct TripEntry: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    let loggedAt: Date
    let distanceKm: Double
    let vehicle: VehicleKind
    let co2Kg: Double
    /// Seconds from trip start to end when recorded by GPS sessions; nil for manual-only logs.
    let durationSeconds: Double?
    /// Polyline samples for map summary; nil when not captured.
    let routePoints: [TripRoutePoint]?

    init(
        id: UUID = UUID(),
        loggedAt: Date = .now,
        distanceKm: Double,
        vehicle: VehicleKind,
        co2Kg: Double,
        durationSeconds: Double? = nil,
        routePoints: [TripRoutePoint]? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.distanceKm = distanceKm
        self.vehicle = vehicle
        self.co2Kg = co2Kg
        self.durationSeconds = durationSeconds
        self.routePoints = routePoints
    }
}
