//
//  AppHeaderWordmark.swift
//  AirGuard
//

import SwiftUI

/// Full transparent wordmark shown at the top of each main screen.
struct AppHeaderWordmark: View {
    /// Wordmark is wide (~2:1); height drives legibility next to large titles.
    private let maxHeight: CGFloat = 112

    var body: some View {
        Image("AppHeaderLogo")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: maxHeight)
            .accessibilityLabel("AirGuard")
    }
}
