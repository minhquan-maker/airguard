//
//  TripSummaryRouter.swift
//  AirGuard
//

import Foundation
import Observation

@Observable
final class TripSummaryRouter {
    /// When set, `RootView` presents ``TripSummaryView`` for this trip.
    var presentedTrip: TripEntry?
}
