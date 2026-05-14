//
//  HomeViewModel.swift
//  AirGuard
//

import Foundation
import Observation

@Observable
final class HomeViewModel {
    private let trips: TripStore
    private let profile: UserProfileStore

    init(trips: TripStore, profile: UserProfileStore) {
        self.trips = trips
        self.profile = profile
    }

    var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    var greetingSubtitle: String {
        "How did you move today?"
    }

    var displayNameSnippet: String {
        let n = profile.profile.displayName
        return n.isEmpty ? "" : ", \(n)"
    }

    var todayUsedKg: Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return trips.trips
            .filter { cal.isDate($0.loggedAt, inSameDayAs: start) }
            .reduce(0) { $0 + $1.co2Kg }
    }

    var dailyBudgetKg: Double {
        profile.dailyBudgetKg
    }

    var remainingBudgetKg: Double {
        max(0, dailyBudgetKg - todayUsedKg)
    }

    var budgetCaption: String {
        let r = remainingBudgetKg
        return String(format: "About %.2f kg CO₂e left in today’s budget.", r)
    }

    var streakDays: Int {
        Self.streakDays(from: trips.trips)
    }

    var streakCaption: String { "Logging streak" }

    var scoreHeadline: String {
        let (h, _) = Self.scoreCopy(trips: trips.trips, budgetKg: dailyBudgetKg)
        return h
    }

    var scoreSubtext: String {
        let (_, s) = Self.scoreCopy(trips: trips.trips, budgetKg: dailyBudgetKg)
        return s
    }

    private static func streakDays(from trips: [TripEntry]) -> Int {
        guard !trips.isEmpty else { return 0 }
        let cal = Calendar.current
        let dayStarts = Set(trips.map { cal.startOfDay(for: $0.loggedAt) })
        guard let newest = dayStarts.max() else { return 0 }
        var count = 0
        var cursor = newest
        while dayStarts.contains(cursor) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    private static func scoreCopy(trips: [TripEntry], budgetKg: Double) -> (String, String) {
        let cal = Calendar.current
        let now = Date()
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: now) else {
            return ("Welcome", "Log trips to see your trend.")
        }
        let recent = trips.filter { $0.loggedAt >= weekAgo }
        let used = recent.reduce(0) { $0 + $1.co2Kg }
        if recent.isEmpty {
            return ("Welcome", "Log your first trip to start tracking.")
        }
        let weeklyReference = budgetKg * 7
        if used <= weeklyReference * 0.8 {
            return ("Great", "Below ~80% of your rolling weekly reference.")
        }
        if used <= weeklyReference * 1.1 {
            return ("On track", "Close to your rolling weekly reference.")
        }
        return ("Heads up", "Above your rolling weekly reference — small shifts help.")
    }
}
