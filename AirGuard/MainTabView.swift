//
//  MainTabView.swift
//  AirGuard
//

import SwiftUI

struct MainTabView: View {
    @Environment(TripStore.self) private var tripStore
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(MotionAutoTripTracker.self) private var motionTracker
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(1)

            NavigationStack {
                LogTripView()
            }
            .tabItem { Label("Log", systemImage: "plus.circle.fill") }
            .tag(2)

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(4)
        }
        .tint(AppTheme.keyGreen)
        .onAppear {
            motionTracker.bind(tripStore: tripStore, profileStore: profileStore)
            motionTracker.applyPolicyFromProfile()
        }
        .onChange(of: profileStore.profile.autoMotionTrackingEnabled) { _, _ in
            motionTracker.applyPolicyFromProfile()
        }
        .onChange(of: profileStore.profile.hasCompletedWelcome) { _, completed in
            if !completed {
                motionTracker.stopAll()
            } else {
                motionTracker.applyPolicyFromProfile()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                motionTracker.applyPolicyFromProfile()
            }
        }
    }
}
