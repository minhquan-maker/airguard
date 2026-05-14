//
//  DailyGaugeView.swift
//  AirGuard
//

import SwiftUI

struct DailyGaugeView: View {
    let usedKg: Double
    let budgetKg: Double

    private var progress: CGFloat {
        guard budgetKg > 0 else { return 0 }
        return CGFloat(min(1, max(0, usedKg / budgetKg)))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.textPrimary.opacity(0.12), lineWidth: 18)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.keyGreen,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(String(format: "%.2f", usedKg))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("kg CO₂e")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: 220, height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today emissions")
        .accessibilityValue(String(format: "%.2f kilograms of %.2f budget", usedKg, budgetKg))
    }
}
