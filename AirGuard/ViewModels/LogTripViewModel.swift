//
//  LogTripViewModel.swift
//  AirGuard
//

import Foundation
import Observation

@Observable
final class LogTripViewModel {
    var distanceText: String = ""
    var selectedVehicle: VehicleKind?

    var parsedDistanceKm: Double? {
        let trimmed = distanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let v = Double(trimmed.replacingOccurrences(of: ",", with: ".")), v > 0 else {
            return nil
        }
        return v
    }

    var canCalculate: Bool {
        parsedDistanceKm != nil && selectedVehicle != nil
    }

    func previewCo2Kg() -> Double? {
        guard let km = parsedDistanceKm, let v = selectedVehicle else { return nil }
        return EmissionEngine.tripCO2Kg(distanceKm: km, vehicle: v)
    }

    func buildTripDraft() -> TripEntry? {
        guard let km = parsedDistanceKm, let v = selectedVehicle else { return nil }
        let kg = EmissionEngine.tripCO2Kg(distanceKm: km, vehicle: v)
        return TripEntry(distanceKm: km, vehicle: v, co2Kg: kg)
    }

    func resetForm() {
        distanceText = ""
        selectedVehicle = nil
    }
}
