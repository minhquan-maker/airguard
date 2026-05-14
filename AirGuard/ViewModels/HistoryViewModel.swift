//
//  HistoryViewModel.swift
//  AirGuard
//

import Foundation
import Observation

struct HistoryDaySection: Identifiable, Equatable {
    let id: Date
    let dayStart: Date
    let title: String
    let trips: [TripEntry]
}

@Observable
final class HistoryViewModel {
    private let trips: TripStore

    init(trips: TripStore) {
        self.trips = trips
    }

    var sections: [HistoryDaySection] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: trips.trips) { cal.startOfDay(for: $0.loggedAt) }
        let sortedKeys = grouped.keys.sorted(by: >)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return sortedKeys.map { day in
            let trips = (grouped[day] ?? []).sorted { $0.loggedAt > $1.loggedAt }
            return HistoryDaySection(
                id: day,
                dayStart: day,
                title: formatter.string(from: day),
                trips: trips
            )
        }
    }
}
