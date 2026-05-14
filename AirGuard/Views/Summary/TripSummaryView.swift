//
//  TripSummaryView.swift
//  AirGuard
//

import MapKit
import SwiftUI

private extension MKCoordinateRegion {
    init?(coordinates: [CLLocationCoordinate2D], paddingFraction: Double = 0.14) {
        guard !coordinates.isEmpty else { return nil }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }
        let clat = (minLat + maxLat) / 2
        let clon = (minLon + maxLon) / 2
        let latSpan = max((maxLat - minLat) * (1 + paddingFraction * 2), 0.003)
        let lonSpan = max((maxLon - minLon) * (1 + paddingFraction * 2), 0.003)
        self.init(center: CLLocationCoordinate2D(latitude: clat, longitude: clon), span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan))
    }
}

/// Full-screen trip recap (Strava-style metrics + route).
struct TripSummaryView: View {
    let trip: TripEntry
    var onClose: () -> Void

    @State private var mapPosition: MapCameraPosition = .automatic

    private var coordinates: [CLLocationCoordinate2D] {
        (trip.routePoints ?? []).map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var milkTeaText: String {
        CarbonEquivalentKind.milkTea.description(forTripKg: trip.co2Kg)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.18, blue: 0.12),
                        Color(red: 0.2, green: 0.24, blue: 0.16),
                        AppTheme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Text("Trip summary")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.top, 8)

                        HStack(alignment: .top, spacing: 0) {
                            statColumn(title: "Distance", value: String(format: "%.1f km", trip.distanceKm))
                            statColumn(title: "Time", value: formatDuration(trip.durationSeconds))
                            statColumn(title: "CO₂e", value: String(format: "%.2f kg", trip.co2Kg))
                        }
                        .padding(.horizontal, 8)

                        VStack(spacing: 10) {
                            Text("Carbon equivalent")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                            HStack(spacing: 10) {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.keyGreen)
                                Text(milkTeaText)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 20)

                        routeSection
                            .padding(.horizontal, 16)

                        Text(trip.vehicle.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.bottom, 24)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                updateMapCamera()
            }
        }
    }

    @ViewBuilder
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            if coordinates.count >= 2 {
                Map(position: $mapPosition) {
                    MapPolyline(coordinates: coordinates)
                        .stroke(AppTheme.keyGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
                .mapStyle(.standard(elevation: .flat))
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            } else if let c = coordinates.first {
                Map(position: $mapPosition) {
                    Annotation("", coordinate: c) {
                        Circle()
                            .fill(AppTheme.keyGreen)
                            .frame(width: 12, height: 12)
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ContentUnavailableView(
                    "No route recorded",
                    systemImage: "location.slash",
                    description: Text("GPS trips include a path. Manual entries from the Log tab have distance only.")
                )
                .frame(height: 180)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func statColumn(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatDuration(_ seconds: Double?) -> String {
        guard let s = seconds, s >= 1 else { return "—" }
        let total = Int(s.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let sec = total % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        if m > 0 {
            return "\(m)m \(sec)s"
        }
        return "\(sec)s"
    }

    private func updateMapCamera() {
        guard !coordinates.isEmpty else { return }
        if coordinates.count >= 2, let region = MKCoordinateRegion(coordinates: coordinates) {
            mapPosition = .region(region)
        } else if let c = coordinates.first {
            mapPosition = .region(MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)))
        }
    }
}
