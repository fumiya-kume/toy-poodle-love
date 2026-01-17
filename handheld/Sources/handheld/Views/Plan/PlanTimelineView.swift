import SwiftUI

struct PlanTimelineView: View {
    @Bindable var viewModel: PlanGeneratorViewModel

    var body: some View {
        List {
            ForEach(Array(viewModel.generatedSpots.enumerated()), id: \.element.id) { index, spot in
                Section {
                    TimelineSpotCard(
                        spot: spot,
                        index: index + 1,
                        scheduledTime: viewModel.generatedPlan?.formattedScheduledTime(for: spot),
                        onTap: {
                            viewModel.showSpotDetail(spot)
                        },
                        onToggleFavorite: {
                            viewModel.toggleFavorite(for: spot)
                        },
                        onNavigate: {
                            openNavigation(to: spot)
                        },
                        onUpdateDuration: { minutes in
                            viewModel.updateStayDuration(for: spot, by: minutes)
                        }
                    )
                } header: {
                    if index > 0, let travelTime = spot.formattedTravelTimeFromPrevious {
                        TravelInfoHeader(
                            travelTime: travelTime,
                            distance: spot.formattedDistanceFromPrevious
                        )
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .onMove { from, to in
                viewModel.reorderSpots(from: from, to: to)
                Task {
                    await viewModel.recalculateRoutes()
                }
            }
            .onDelete { offsets in
                viewModel.deleteSpot(at: offsets)
                Task {
                    await viewModel.recalculateRoutes()
                }
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    private func openNavigation(to spot: PlanSpot) {
        let urlString = "maps://?daddr=\(spot.latitude),\(spot.longitude)&dirflg=d"
        if let url = URL(string: urlString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

struct TravelInfoHeader: View {
    let travelTime: String
    let distance: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "car.fill")
                .foregroundStyle(.secondary)

            Text(travelTime)
                .font(.caption)

            if let distance = distance {
                Text("(\(distance))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PlanTimelineView(viewModel: PlanGeneratorViewModel())
}
