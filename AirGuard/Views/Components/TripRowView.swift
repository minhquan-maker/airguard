//
//  TripRowView.swift
//  AirGuard
//

import SwiftUI

struct TripRowView: View {
    let trip: TripEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: trip.vehicle.systemImageName)
                .font(.title3)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(AppTheme.keyGreen.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.vehicle.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(Self.timeFormatter.string(from: trip.loggedAt)) • \(String(format: "%.0f", trip.distanceKm)) km")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", trip.co2Kg))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("kg CO₂e")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
