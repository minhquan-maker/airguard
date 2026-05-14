//
//  TripNotificationManager.swift
//  AirGuard
//

import Foundation
import UserNotifications

extension Notification.Name {
    /// Posted when the user taps a “trip completed” local notification. `userInfo["tripId"]` is a `UUID`.
    static let airGuardOpenTripSummary = Notification.Name("AirGuard.openTripSummary")
}

enum TripNotificationManager {
    private static let tripIdKey = "tripId"

    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Schedules a local notification after a trip is saved (auto, manual GPS, or debug).
    static func deliverTripCompletedNotification(trip: TripEntry) {
        let content = UNMutableNotificationContent()
        content.title = "Trip complete"
        content.body = String(
            format: "You just completed %.1f km. Tap to see your summary.",
            trip.distanceKm
        )
        content.sound = .default
        content.userInfo = [tripIdKey: trip.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.15, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trip-complete-\(trip.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func tripId(from response: UNNotificationResponse) -> UUID? {
        guard let s = response.notification.request.content.userInfo[tripIdKey] as? String else { return nil }
        return UUID(uuidString: s)
    }
}
