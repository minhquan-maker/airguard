//
//  WelcomeView.swift
//  AirGuard
//

import SwiftUI

struct WelcomeView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @State private var displayName: String = ""
    @State private var email: String = ""

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 24)
            VStack(spacing: 16) {
                AppHeaderWordmark()
                    .padding(.horizontal, 8)
                Text("Track the carbon footprint of how you move.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Display name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("e.g. Alex", text: $displayName)
                    .textContentType(.name)
                    .padding(14)
                    .background(AppTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("Email (optional)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding(14)
                    .background(AppTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 32)

            Button {
                profileStore.completeWelcome(displayName: displayName, email: email)
            } label: {
                HStack {
                    Text("Get started")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canContinue ? AppTheme.keyGreen : AppTheme.textPrimary.opacity(0.2))
                .foregroundStyle(canContinue ? AppTheme.textPrimary : AppTheme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!canContinue)
            .padding(.horizontal, 32)

            Text("Your data is stored on-device for this MVP.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .background(AppTheme.background)
    }
}
