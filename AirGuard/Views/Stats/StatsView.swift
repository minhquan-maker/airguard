//
//  StatsView.swift
//  AirGuard
//

import Charts
import SwiftUI

struct StatsView: View {
    @Environment(TripStore.self) private var tripStore

    var body: some View {
        let vm = StatsViewModel(trips: tripStore)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeaderWordmark()
                summaryCard(vm: vm)
                chartCard(vm: vm)
                if let cap = vm.highlightCaption {
                    insightCard(text: cap)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(AppTheme.background)
        .navigationTitle("Statistics")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
    }

    private func summaryCard(vm: StatsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(vm.weekOverWeekCaption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(String(format: "%.2f", vm.weekTotalKg))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("kg CO₂e")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func chartCard(vm: StatsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 days")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Chart(vm.lastSevenDays) { bar in
                BarMark(
                    x: .value("Day", bar.label),
                    y: .value("kg", bar.co2Kg)
                )
                .foregroundStyle(AppTheme.keyGreen)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(20)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func insightCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppTheme.keyGreen)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.keyGreen.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
