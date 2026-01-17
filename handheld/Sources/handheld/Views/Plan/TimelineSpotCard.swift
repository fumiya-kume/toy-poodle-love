import SwiftUI

struct TimelineSpotCard: View {
    let spot: PlanSpot
    let index: Int
    let scheduledTime: String?
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onNavigate: () -> Void
    let onUpdateDuration: (Int) -> Void

    @State private var showDurationStepper = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 32, height: 32)
                            Text("\(index)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }

                        if let time = scheduledTime {
                            Text(time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(spot.formattedStayDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: onToggleFavorite) {
                            Image(systemName: spot.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(spot.isFavorite ? .red : .secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: onNavigate) {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)

            if showDurationStepper {
                Divider()
                StayDurationStepper(
                    duration: spot.formattedStayDuration,
                    onDecrease: { onUpdateDuration(-15) },
                    onIncrease: { onUpdateDuration(15) }
                )
                .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onLongPressGesture {
            showDurationStepper.toggle()
        }
    }
}

struct StayDurationStepper: View {
    let duration: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack {
            Text("滞在時間")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text(duration)
                    .font(.body)
                    .monospacedDigit()
                    .frame(minWidth: 60)

                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    VStack {
        TimelineSpotCard(
            spot: PlanSpot(
                order: 0,
                name: "東京タワー",
                address: "東京都港区",
                coordinate: .init(latitude: 35.6586, longitude: 139.7454),
                aiDescription: "東京の象徴的なランドマーク",
                estimatedStayDuration: 3600
            ),
            index: 1,
            scheduledTime: "10:00",
            onTap: {},
            onToggleFavorite: {},
            onNavigate: {},
            onUpdateDuration: { _ in }
        )
    }
    .padding()
}
