//
//  AirGuardApp.swift
//  AirGuard
//

import SwiftUI

@main
struct AirGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var tripStore = TripStore()
    @State private var profileStore = UserProfileStore()
    @State private var motionTracker = MotionAutoTripTracker()
    @State private var tripSummaryRouter = TripSummaryRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(tripStore)
                .environment(profileStore)
                .environment(motionTracker)
                .environment(tripSummaryRouter)
                .tint(AppTheme.keyGreen)
        }
    }
}
