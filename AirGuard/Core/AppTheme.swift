//
//  AppTheme.swift
//  AirGuard
//
//  Latte palette from product spec (Figma).
//

import SwiftUI

enum AppTheme {
    static let background = Color(hex: 0xE1DBC7)
    static let keyGreen = Color(hex: 0x7FBD45)
    static let textPrimary = Color(hex: 0x2A4731)
    static let textSecondary = Color(hex: 0x2A4731).opacity(0.65)
    static let cardSurface = Color.white.opacity(0.55)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
