//
//  EmissionEngine.swift
//  AirGuard
//
//  TTW factors — numeric values from dataset_research.html (AirGuard MVP).
//

import Foundation

enum DailyBudgetConstants {
    static let globalReferenceKgCO2PerDay = 6.8
    static let vietnamDefaultKgCO2PerDay = 9.6
}

/// Vehicle identifiers (stable `rawValue` for persistence).
enum VehicleKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case motorbike
    case motorbike_ev
    case car_small
    case car_medium
    case car_large
    case car_diesel
    case car_hybrid
    case car_ev
    case bus_diesel
    case bus_ev
    case taxi
    case mrt
    case train_diesel
    case walk

    var id: String { rawValue }

    /// UI title (English).
    var title: String {
        switch self {
        case .motorbike: return "Motorbike (petrol)"
        case .motorbike_ev: return "Electric motorbike"
        case .car_small: return "Small car (<1.5 L)"
        case .car_medium: return "Medium car (1.5–2.5 L)"
        case .car_large: return "Large car (>2.5 L)"
        case .car_diesel: return "Diesel car"
        case .car_hybrid: return "Hybrid car"
        case .car_ev: return "Electric car"
        case .bus_diesel: return "Diesel bus"
        case .bus_ev: return "Electric bus"
        case .taxi: return "Taxi / ride-hail"
        case .mrt: return "Metro / urban rail"
        case .train_diesel: return "Diesel train"
        case .walk: return "Walk"
        }
    }

    var systemImageName: String {
        switch self {
        case .motorbike, .motorbike_ev: return "motorcycle"
        case .car_small, .car_medium, .car_large, .car_diesel, .car_hybrid: return "car.side"
        case .car_ev: return "bolt.car.fill"
        case .bus_diesel, .bus_ev: return "bus"
        case .taxi: return "car.side.front.open"
        case .mrt: return "tram.fill"
        case .train_diesel: return "tram.fill"
        case .walk: return "figure.walk"
        }
    }

    /// kg CO₂ per km (TTW). Same numeric values as research dataset.
    var emissionFactorKgPerKm: Double {
        switch self {
        case .motorbike: return 0.085
        case .motorbike_ev: return 0
        case .car_small: return 0.1431
        case .car_medium: return 0.1747
        case .car_large: return 0.2683
        case .car_diesel: return 0.1730
        case .car_hybrid: return 0.1283
        case .car_ev: return 0
        case .bus_diesel: return 0.1253
        case .bus_ev: return 0
        case .taxi: return 0.1486
        case .mrt: return 0.0286
        case .train_diesel: return 0.120
        case .walk: return 0
        }
    }

    var isElectric: Bool {
        switch self {
        case .motorbike_ev, .car_ev, .bus_ev: return true
        default: return false
        }
    }

    var subtitleFactorText: String? {
        if isElectric { return "0 kg CO₂/km (tailpipe)" }
        return nil
    }
}

enum EmissionEngine {
    static func tripCO2Kg(distanceKm: Double, vehicle: VehicleKind) -> Double {
        let raw = distanceKm * vehicle.emissionFactorKgPerKm
        return (raw * 100).rounded() / 100
    }
}

enum CarbonEquivalentKind: String, CaseIterable, Identifiable {
    case milkTea
    var id: String { rawValue }
    var kgPerUnit: Double {
        switch self {
        case .milkTea: return 0.110
        }
    }
    var unitLabel: String {
        switch self {
        case .milkTea: return "cups"
        }
    }
    var itemLabel: String {
        switch self {
        case .milkTea: return "milk tea (250 ml)"
        }
    }

    func description(forTripKg co2: Double) -> String {
        let n = max(0, Int((co2 / kgPerUnit).rounded()))
        return "≈ \(n) \(unitLabel) of \(itemLabel)"
    }
}
