//
//  UserProfile.swift
//  AirGuard
//

import Foundation

struct UserProfile: Codable, Equatable, Sendable {
    var displayName: String
    var email: String?
    var hasCompletedWelcome: Bool
    /// When true, daily budget uses the stricter global reference (6.8 kg).
    var strictDailyBudget: Bool
    /// When true, listens for automotive motion and GPS to log trips automatically.
    var autoMotionTrackingEnabled: Bool
    /// `VehicleKind.rawValue` used for auto-tracked trips (default motorbike).
    var defaultAutoVehicleRaw: String

    var defaultAutoVehicleKind: VehicleKind {
        VehicleKind(rawValue: defaultAutoVehicleRaw) ?? .motorbike
    }

    static let placeholder = UserProfile(
        displayName: "",
        email: nil,
        hasCompletedWelcome: false,
        strictDailyBudget: false,
        autoMotionTrackingEnabled: false,
        defaultAutoVehicleRaw: VehicleKind.motorbike.rawValue
    )

    enum CodingKeys: String, CodingKey {
        case displayName
        case email
        case hasCompletedWelcome
        case strictDailyBudget
        case autoMotionTrackingEnabled
        case defaultAutoVehicleRaw
    }

    init(
        displayName: String,
        email: String?,
        hasCompletedWelcome: Bool,
        strictDailyBudget: Bool,
        autoMotionTrackingEnabled: Bool,
        defaultAutoVehicleRaw: String
    ) {
        self.displayName = displayName
        self.email = email
        self.hasCompletedWelcome = hasCompletedWelcome
        self.strictDailyBudget = strictDailyBudget
        self.autoMotionTrackingEnabled = autoMotionTrackingEnabled
        self.defaultAutoVehicleRaw = defaultAutoVehicleRaw
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email)
        hasCompletedWelcome = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedWelcome) ?? false
        strictDailyBudget = try c.decodeIfPresent(Bool.self, forKey: .strictDailyBudget) ?? false
        autoMotionTrackingEnabled = try c.decodeIfPresent(Bool.self, forKey: .autoMotionTrackingEnabled) ?? false
        defaultAutoVehicleRaw = try c.decodeIfPresent(String.self, forKey: .defaultAutoVehicleRaw)
            ?? VehicleKind.motorbike.rawValue
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(displayName, forKey: .displayName)
        try c.encodeIfPresent(email, forKey: .email)
        try c.encode(hasCompletedWelcome, forKey: .hasCompletedWelcome)
        try c.encode(strictDailyBudget, forKey: .strictDailyBudget)
        try c.encode(autoMotionTrackingEnabled, forKey: .autoMotionTrackingEnabled)
        try c.encode(defaultAutoVehicleRaw, forKey: .defaultAutoVehicleRaw)
    }
}
