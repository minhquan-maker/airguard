//
//  UserProfileStore.swift
//  AirGuard
//

import Foundation
import Observation

@Observable
final class UserProfileStore {
    private(set) var profile: UserProfile = .placeholder

    private let storageKey = "airguard.profile.v1"

    init() {
        load()
    }

    var dailyBudgetKg: Double {
        profile.strictDailyBudget
            ? DailyBudgetConstants.globalReferenceKgCO2PerDay
            : DailyBudgetConstants.vietnamDefaultKgCO2PerDay
    }

    func completeWelcome(displayName: String, email: String?) {
        profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        profile.hasCompletedWelcome = true
        save()
    }

    func signOut() {
        profile = .placeholder
        save()
    }

    func setStrictBudget(_ value: Bool) {
        profile.strictDailyBudget = value
        save()
    }

    func setAutoMotionTrackingEnabled(_ value: Bool) {
        profile.autoMotionTrackingEnabled = value
        save()
    }

    func setDefaultAutoVehicle(_ kind: VehicleKind) {
        profile.defaultAutoVehicleRaw = kind.rawValue
        save()
    }

    func updateDisplayName(_ name: String) {
        profile.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
