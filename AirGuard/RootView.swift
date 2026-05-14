//
//  RootView.swift
//  AirGuard
//

import SwiftUI

struct RootView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(TripStore.self) private var tripStore
    @Environment(TripSummaryRouter.self) private var tripSummaryRouter

    var body: some View {
        @Bindable var summaryRouter = tripSummaryRouter
        Group {
            if profileStore.profile.hasCompletedWelcome {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            TripNotificationManager.requestAuthorizationIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .airGuardOpenTripSummary)) { output in
            guard let id = output.userInfo?["tripId"] as? UUID else { return }
            summaryRouter.presentedTrip = tripStore.trips.first { $0.id == id }
        }
        .fullScreenCover(item: $summaryRouter.presentedTrip) { trip in
            TripSummaryView(trip: trip) {
                summaryRouter.presentedTrip = nil
            }
        }
    }
}
