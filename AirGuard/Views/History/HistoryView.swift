//
//  HistoryView.swift
//  AirGuard
//

import SwiftUI

struct HistoryView: View {
    @Environment(TripStore.self) private var tripStore
    @Environment(TripSummaryRouter.self) private var tripSummaryRouter

    var body: some View {
        let vm = HistoryViewModel(trips: tripStore)
        VStack(spacing: 0) {
            AppHeaderWordmark()
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity)
                .background(AppTheme.background)
            Group {
                if vm.sections.isEmpty {
                    ContentUnavailableView(
                        "No trips yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Log a trip from the center tab to see it here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.sections) { section in
                            Section(section.title) {
                                ForEach(section.trips) { trip in
                                    Button {
                                        tripSummaryRouter.presentedTrip = trip
                                    } label: {
                                        TripRowView(trip: trip)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Shows trip summary")
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                tripStore.delete(id: trip.id)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.background)
        .navigationTitle("History")
        .toolbarBackground(AppTheme.background, for: .navigationBar)
    }
}
