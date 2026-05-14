//
//  HomeView.swift
//  AirGuard
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(TripStore.self) private var tripStore
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(MotionAutoTripTracker.self) private var motionTracker

    private var viewModel: HomeViewModel {
        HomeViewModel(trips: tripStore, profile: profileStore)
    }

    var body: some View {
        let vm = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AppHeaderWordmark()
                header(vm: vm)
                if profileStore.profile.autoMotionTrackingEnabled || motionTracker.isSessionActive {
                    autoTrackingBanner
                }
                VStack(spacing: 12) {
                    DailyGaugeView(usedKg: vm.todayUsedKg, budgetKg: vm.dailyBudgetKg)
                        .frame(maxWidth: .infinity)
                    Text(vm.budgetCaption)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                HStack(spacing: 12) {
                    scoreCard(
                        title: "Streak",
                        headline: "\(vm.streakDays) days",
                        caption: vm.streakCaption,
                        systemImage: "flame.fill"
                    )
                    scoreCard(
                        title: "Outlook",
                        headline: vm.scoreHeadline,
                        caption: vm.scoreSubtext,
                        systemImage: "leaf.fill"
                    )
                }

                Button {
                    selectedTab = 2
                } label: {
                    HStack {
                        Text("Log trip")
                            .font(.headline)
                        Image(systemName: "plus.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.keyGreen)
                    .foregroundStyle(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(AppTheme.background)
        .navigationTitle("Home")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
    }

    @ViewBuilder
    private func header(vm: HomeViewModel) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(vm.greetingTitle)\(vm.displayNameSnippet)")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(vm.greetingSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.title3)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(10)
                .background(AppTheme.cardSurface)
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
    }

    private var autoTrackingBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: motionTracker.isSessionActive ? "car.circle.fill" : "antenna.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundStyle(AppTheme.keyGreen)
                VStack(alignment: .leading, spacing: 4) {
                    Text(trackingBannerTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    if motionTracker.isSessionActive {
                        Text(String(format: "%.2f km accumulated this session", motionTracker.sessionDistanceMeters / 1000))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Text(trackingBannerListeningCaption)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            if motionTracker.isSessionActive, motionTracker.isManualTripSession {
                HStack(spacing: 10) {
                    Button {
                        motionTracker.stopManualGpsTrip(save: true)
                    } label: {
                        Text("End & save")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.keyGreen)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    Button {
                        motionTracker.stopManualGpsTrip(save: false)
                    } label: {
                        Text("Discard")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.cardSurface)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(AppTheme.keyGreen.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var trackingBannerTitle: String {
        if motionTracker.isSessionActive {
            if motionTracker.isManualTripSession {
                return "GPS trip (manual)"
            }
            return "Auto-tracking: in trip"
        }
        return "Auto-tracking: listening"
    }

    private var trackingBannerListeningCaption: String {
        let vehicle = profileStore.profile.defaultAutoVehicleKind.title
        return "Detects trips using motion (.automotive) and sustained GPS speed (~12s). Default vehicle: \(vehicle). If it stays here while you drive, start a manual GPS trip in Settings."
    }

    private func scoreCard(title: String, headline: String, caption: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(AppTheme.keyGreen)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(headline)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(caption)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
