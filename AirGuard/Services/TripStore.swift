//
//  TripStore.swift
//  AirGuard
//

import Foundation
import Observation

@Observable
final class TripStore {
    private(set) var trips: [TripEntry] = []

    private let storageKey = "airguard.trips.v1"

    init() {
        load()
    }

    func add(_ trip: TripEntry) {
        trips.insert(trip, at: 0)
        save()
        TripNotificationManager.deliverTripCompletedNotification(trip: trip)
    }

    func delete(id: UUID) {
        trips.removeAll { $0.id == id }
        save()
    }

    func replaceAll(_ trips: [TripEntry]) {
        self.trips = trips
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([TripEntry].self, from: data) {
            trips = decoded.sorted { $0.loggedAt > $1.loggedAt }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
