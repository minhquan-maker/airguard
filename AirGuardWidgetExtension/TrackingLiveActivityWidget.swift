//
//  TrackingLiveActivityWidget.swift
//  AirGuardWidgetExtension
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.2, *)
struct TrackingLiveActivityWidget: Widget {
    private let latteBackground = Color(hex: 0xE1DBC7)
    private let latteKey = Color(hex: 0x7FBD45)
    private let latteText = Color(hex: 0x2A4731)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrackingActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image("LiveActivityLogo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                    Text("AirGuard is tracking")
                        .font(.headline)
                        .foregroundStyle(latteText)
                }
                Text(context.state.vehicleName)
                    .font(.subheadline)
                    .foregroundStyle(latteText.opacity(0.75))
                Text(String(format: "%.2f km", context.state.distanceKm))
                    .font(.title3.bold())
                    .foregroundStyle(latteText)
                Text(context.state.isTracking ? "In progress" : "Completed")
                    .font(.caption)
                    .foregroundStyle(latteText.opacity(0.75))
            }
            .padding()
            .activityBackgroundTint(latteBackground)
            .activitySystemActionForegroundColor(latteText)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image("LiveActivityLogo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.1f km", context.state.distanceKm))
                        .font(.headline)
                        .foregroundStyle(latteText)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(latteKey)
                            .frame(width: 8, height: 8)
                        Text(context.state.vehicleName)
                            .font(.subheadline)
                            .foregroundStyle(latteText)
                    }
                }
            } compactLeading: {
                Image("LiveActivityLogo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                Text(String(format: "%.1f", context.state.distanceKm))
                    .foregroundStyle(latteText)
            } minimal: {
                Image("LiveActivityLogo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
            .keylineTint(latteKey)
        }
    }
}

private extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
