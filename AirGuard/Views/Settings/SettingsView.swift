//
//  SettingsView.swift
//  AirGuard
//

import SwiftUI

struct SettingsView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(MotionAutoTripTracker.self) private var motionTracker
    @State private var showSignOutConfirm = false

    var body: some View {
        let vm = SettingsViewModel(profile: profileStore)
        List {
            Section {
                AppHeaderWordmark()
                    .listRowInsets(EdgeInsets(top: 12, leading: 24, bottom: 8, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            Section("Profile") {
                HStack {
                    Text(String(vm.displayName.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .frame(width: 48, height: 48)
                        .background(AppTheme.keyGreen.opacity(0.35))
                        .clipShape(Circle())
                        .foregroundStyle(AppTheme.textPrimary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.displayName.isEmpty ? "Guest" : vm.displayName)
                            .font(.headline)
                        Text(vm.emailLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            Section("Auto trip tracking") {
                Toggle("Detect trips automatically", isOn: Binding(
                    get: { profileStore.profile.autoMotionTrackingEnabled },
                    set: { profileStore.setAutoMotionTrackingEnabled($0) }
                ))
                Text("When enabled, AirGuard listens for driving-style motion, then uses GPS to measure distance. Trips are saved when driving stops (~45s). For best results, allow Always Location and Background App Refresh.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Default vehicle for auto trips", selection: Binding(
                    get: { profileStore.profile.defaultAutoVehicleKind },
                    set: { profileStore.setDefaultAutoVehicle($0) }
                )) {
                    ForEach(VehicleKind.allCases) { v in
                        Text(v.title).tag(v)
                    }
                }
            }

            Section("Manual GPS trip") {
                Text("Starts a real in-trip session using GPS distance (same as auto when moving). Use this if the banner stays on “listening” while you drive. Stop with the buttons below or from Home.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if motionTracker.isManualTripSession {
                    Button {
                        motionTracker.stopManualGpsTrip(save: true)
                    } label: {
                        Label("End trip & save", systemImage: "checkmark.circle.fill")
                    }
                    Button(role: .destructive) {
                        motionTracker.stopManualGpsTrip(save: false)
                    } label: {
                        Label("Discard trip", systemImage: "trash")
                    }
                } else {
                    Button {
                        motionTracker.startManualGpsTrip()
                    } label: {
                        Label("Start GPS trip (manual)", systemImage: "location.fill")
                    }
                    .disabled(motionTracker.isSessionActive)
                }
            }

            #if DEBUG
            Section("Developer tools") {
                if motionTracker.isDebugSimulationActive {
                    Button(role: .destructive) {
                        motionTracker.stopDebugTripSimulation()
                    } label: {
                        Label("Stop simulated in-trip", systemImage: "stop.circle.fill")
                    }
                } else {
                    Button {
                        motionTracker.startDebugTripSimulation()
                    } label: {
                        Label("Simulate in-trip (Live Activity)", systemImage: "play.circle.fill")
                    }
                }

                Text("Debug only: creates a fake moving session and updates Live Activity every ~2s.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            #endif

            Section("CO₂ budget (reference)") {
                Toggle("Strict daily budget (6.8 kg)", isOn: Binding(
                    get: { profileStore.profile.strictDailyBudget },
                    set: { profileStore.setStrictBudget($0) }
                ))
                Text(vm.budgetExplanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                NavigationLink {
                    MethodologyView()
                } label: {
                    Label("Methodology (TTW)", systemImage: "doc.text")
                }
                LabeledContent("Privacy") {
                    Text("On-device only")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Version") {
                    Text(vm.appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Settings")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                vm.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will return to the welcome screen. Trip history stays on this device.")
        }
    }
}

private struct MethodologyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AppHeaderWordmark()
                Text(
                    """
                    AirGuard MVP uses Tank-to-Wheel (TTW) emission factors: trip CO₂ equals distance multiplied by a vehicle-specific factor.

                    Sources align with the AirGuard research dataset (DEFRA 2025 family values with ICCT Asia adjustment for motorbikes in Southeast Asia). Electric tailpipe factors are zero; grid electricity can be layered in a future version.

                    This build stores data locally on your device (UserDefaults). It does not send data to a server.
                    """
                )
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Methodology")
    }
}
