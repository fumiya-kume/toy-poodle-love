import SwiftUI
import MapKit

struct SpotDetailSheet: View {
    let spot: PlanSpot
    let onToggleFavorite: () -> Void
    let onNavigate: () -> Void

    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                lookAroundSection

                VStack(alignment: .leading, spacing: 8) {
                    Text(spot.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Label(spot.address, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !spot.aiDescription.isEmpty {
                    Text(spot.aiDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    InfoBadge(icon: "clock", label: spot.formattedStayDuration)

                    if let travelTime = spot.formattedTravelTimeFromPrevious {
                        InfoBadge(icon: "car", label: travelTime)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    Button(action: onToggleFavorite) {
                        Label(
                            spot.isFavorite ? "お気に入り解除" : "お気に入り",
                            systemImage: spot.isFavorite ? "heart.fill" : "heart"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(spot.isFavorite ? .red : .accentColor)

                    Button(action: onNavigate) {
                        Label("ナビ開始", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .task {
            await fetchLookAround()
        }
    }

    @ViewBuilder
    private var lookAroundSection: some View {
        if isLoadingLookAround {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 200)
                .overlay {
                    ProgressView()
                }
        } else if let scene = lookAroundScene {
            LookAroundPreview(initialScene: scene)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: spot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(spot.name, coordinate: spot.coordinate)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)
        }
    }

    private func fetchLookAround() async {
        isLoadingLookAround = true
        let request = MKLookAroundSceneRequest(coordinate: spot.coordinate)
        do {
            lookAroundScene = try await request.scene
        } catch {
            lookAroundScene = nil
        }
        isLoadingLookAround = false
    }
}

struct InfoBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
    }
}

#Preview {
    SpotDetailSheet(
        spot: PlanSpot(
            order: 0,
            name: "東京タワー",
            address: "東京都港区芝公園4丁目2-8",
            coordinate: .init(latitude: 35.6586, longitude: 139.7454),
            aiDescription: "1958年に完成した東京の象徴的なランドマーク。展望台からは東京の街並みを一望できます。",
            estimatedStayDuration: 3600
        ),
        onToggleFavorite: {},
        onNavigate: {}
    )
}
