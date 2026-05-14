//
//  LogTripView.swift
//  AirGuard
//

import SwiftUI

struct LogTripView: View {
    @Environment(TripStore.self) private var tripStore
    @State private var viewModel = LogTripViewModel()
    @State private var resultTrip: TripEntry?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AppHeaderWordmark()
                sectionTitle("Distance (km)")
                TextField("0", text: $viewModel.distanceText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .padding(16)
                    .background(AppTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(AppTheme.textPrimary)

                sectionTitle("Vehicle")
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(VehicleKind.allCases) { vehicle in
                        vehicleButton(vehicle)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(AppTheme.background)
        .navigationTitle("Log trip")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            calculateButton
        }
        .sheet(item: $resultTrip) { trip in
            TripResultView(
                trip: trip,
                equivalentText: CarbonEquivalentKind.milkTea.description(forTripKg: trip.co2Kg),
                onSave: {
                    tripStore.add(trip)
                    viewModel.resetForm()
                    resultTrip = nil
                },
                onDiscard: {
                    resultTrip = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
    }

    private func vehicleButton(_ vehicle: VehicleKind) -> some View {
        let selected = viewModel.selectedVehicle == vehicle
        return Button {
            viewModel.selectedVehicle = vehicle
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: vehicle.systemImageName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(vehicle.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let sub = vehicle.subtitleFactorText {
                    Text(sub)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(selected ? AppTheme.keyGreen.opacity(0.35) : AppTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? AppTheme.keyGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var calculateButton: some View {
        Button {
            resultTrip = viewModel.buildTripDraft()
        } label: {
            HStack {
                Text("Calculate")
                    .font(.headline)
                Image(systemName: "chevron.right")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canCalculate ? AppTheme.keyGreen : AppTheme.textPrimary.opacity(0.2))
            .foregroundStyle(viewModel.canCalculate ? AppTheme.textPrimary : AppTheme.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!viewModel.canCalculate)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.background.opacity(0.95))
    }
}
