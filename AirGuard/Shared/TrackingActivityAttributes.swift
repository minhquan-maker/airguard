//
//  TrackingActivityAttributes.swift
//  AirGuard
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.2, *)
struct TrackingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var vehicleName: String
        var distanceKm: Double
        var startedAt: Date
        var isTracking: Bool
    }

    var title: String
}
#endif
