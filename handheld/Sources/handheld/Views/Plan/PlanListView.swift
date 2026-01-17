import SwiftUI

struct PlanListView: View {
    @Bindable var viewModel: PlanGeneratorViewModel

    var body: some View {
        List {
            ForEach(Array(viewModel.generatedSpots.enumerated()), id: \.element.id) { index, spot in
                SpotListRow(
                    spot: spot,
                    index: index + 1,
                    onTap: {
                        viewModel.showSpotDetail(spot)
                    }
                )
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
    }
}

struct SpotListRow: View {
    let spot: PlanSpot
    let index: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)
                    Text("\(index)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(spot.formattedStayDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if spot.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanListView(viewModel: PlanGeneratorViewModel())
}
