//
//  StatsViewModel.swift
//  AirGuard
//

import Foundation
import Observation

struct DayBar: Identifiable, Equatable {
    let id: Date
    let label: String
    let co2Kg: Double
}

@Observable
final class StatsViewModel {
    private let trips: TripStore

    init(trips: TripStore) {
        self.trips = trips
    }

    /// Last 7 calendar days ending today, each value is total kg that day.
    var lastSevenDays: [DayBar] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [DayBar] = []
        let short = DateFormatter()
        short.locale = Locale(identifier: "en_US_POSIX")
        short.dateFormat = "EEE"
        for offset in (0..<7).reversed() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let kg = trips.trips
                .filter { cal.isDate($0.loggedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.co2Kg }
            result.append(DayBar(id: day, label: short.string(from: day), co2Kg: kg))
        }
        return result
    }

    var weekTotalKg: Double {
        lastSevenDays.reduce(0) { $0 + $1.co2Kg }
    }

    var previousWeekTotalKg: Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let startPrev = cal.date(byAdding: .day, value: -14, to: today),
              let endPrev = cal.date(byAdding: .day, value: -7, to: today) else { return 0 }
        return trips.trips
            .filter { $0.loggedAt >= startPrev && $0.loggedAt < endPrev }
            .reduce(0) { $0 + $1.co2Kg }
    }

    var weekOverWeekPercent: Double? {
        let prev = previousWeekTotalKg
        guard prev > 0.0001 else { return nil }
        return (weekTotalKg - prev) / prev * 100
    }

    var weekOverWeekCaption: String {
        guard let p = weekOverWeekPercent else {
            return "Not enough history for a week-over-week comparison."
        }
        return String(format: "%+.1f%% vs last week", p)
    }

    var highlightCaption: String? {
        let bars = lastSevenDays
        guard let maxBar = bars.max(by: { $0.co2Kg < $1.co2Kg }), maxBar.co2Kg > 0 else {
            return nil
        }
        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: "en_US_POSIX")
        dayFmt.dateFormat = "EEEE"
        return "\(dayFmt.string(from: maxBar.id)) was your highest day (\(String(format: "%.1f", maxBar.co2Kg)) kg CO₂e)."
    }
}
