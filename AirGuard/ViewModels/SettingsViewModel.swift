//
//  SettingsViewModel.swift
//  AirGuard
//

import Foundation
import Observation

@Observable
final class SettingsViewModel {
    private let profile: UserProfileStore

    init(profile: UserProfileStore) {
        self.profile = profile
    }

    var displayName: String { profile.profile.displayName }
    var emailLine: String {
        profile.profile.email ?? "No email on file"
    }

    var strictBudget: Bool {
        get { profile.profile.strictDailyBudget }
        set { profile.setStrictBudget(newValue) }
    }

    var budgetExplanation: String {
        if profile.profile.strictDailyBudget {
            return String(format: "Strict mode uses the global 1.5°C-style reference (%.1f kg CO₂e/day).", DailyBudgetConstants.globalReferenceKgCO2PerDay)
        }
        return String(format: "Default uses a Vietnam per-capita reference (~%.1f kg CO₂e/day).", DailyBudgetConstants.vietnamDefaultKgCO2PerDay)
    }

    var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    func signOut() {
        profile.signOut()
    }
}
