//
//  TripResultView.swift
//  AirGuard
//

import SwiftUI

struct TripResultView: View {
    let trip: TripEntry
    let equivalentText: String
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                AppHeaderWordmark()
                Text(String(format: "%.2f kg CO₂e", trip.co2Kg))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Distance \(String(format: "%.1f", trip.distanceKm)) km × \(trip.vehicle.title)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(equivalentText)
                    .font(.callout)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onSave) {
                        Text("Save trip")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.keyGreen)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    Button("Discard", role: .cancel, action: onDiscard)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AppTheme.background)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
