import SwiftUI
import SwiftData
import MapKit

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Picker("表示", selection: $viewModel.selectedTab) {
                ForEach(FavoritesTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if viewModel.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("お気に入り")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData(context: modelContext)
        }
        .sheet(isPresented: $viewModel.showPlanDetail) {
            if let plan = viewModel.selectedPlan {
                NavigationStack {
                    SavedPlanDetailView(plan: plan)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") {
                                    viewModel.showPlanDetail = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            viewModel.emptyMessage,
            systemImage: viewModel.emptyIcon,
            description: Text(viewModel.selectedTab == .plans
                ? "プラン作成画面からプランを作成・保存できます"
                : "プラン内のスポットをお気に入りに追加できます")
        )
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.selectedTab {
        case .plans:
            plansList
        case .spots:
            spotsList
        }
    }

    private var plansList: some View {
        List {
            ForEach(viewModel.plans) { plan in
                Button {
                    viewModel.selectPlan(plan)
                } label: {
                    PlanRowView(plan: plan)
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                viewModel.deletePlans(at: offsets, context: modelContext)
            }
        }
        .listStyle(.plain)
    }

    private var spotsList: some View {
        List {
            ForEach(viewModel.favoriteSpots) { spot in
                FavoriteSpotRowView(spot: spot)
            }
            .onDelete { offsets in
                viewModel.deleteFavoriteSpots(at: offsets, context: modelContext)
            }
        }
        .listStyle(.plain)
    }
}

struct PlanRowView: View {
    let plan: SightseeingPlan

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "map")
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(plan.spots.count)箇所", systemImage: "mappin")
                    Text(plan.formattedCreatedAt)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FavoriteSpotRowView: View {
    let spot: FavoriteSpot

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(spot.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                openNavigation(to: spot)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func openNavigation(to spot: FavoriteSpot) {
        let urlString = "maps://?daddr=\(spot.latitude),\(spot.longitude)&dirflg=d"
        if let url = URL(string: urlString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

struct SavedPlanDetailView: View {
    let plan: SightseeingPlan
    @State private var viewMode: PlanGeneratorViewModel.ViewMode = .timeline

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Picker("表示モード", selection: $viewMode) {
                ForEach(PlanGeneratorViewModel.ViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            savedPlanContent
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            Label(plan.formattedTotalDuration, systemImage: "clock")
            Label(plan.formattedTotalDistance, systemImage: "car")
            Label("\(plan.spots.count)箇所", systemImage: "mappin")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private var savedPlanContent: some View {
        switch viewMode {
        case .timeline:
            SavedPlanTimelineView(spots: plan.sortedSpots, plan: plan)
        case .map:
            SavedPlanMapView(spots: plan.sortedSpots)
        case .list:
            SavedPlanListView(spots: plan.sortedSpots)
        }
    }
}

struct SavedPlanTimelineView: View {
    let spots: [PlanSpot]
    let plan: SightseeingPlan

    var body: some View {
        List {
            ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                Section {
                    SavedSpotCard(
                        spot: spot,
                        index: index + 1,
                        scheduledTime: plan.formattedScheduledTime(for: spot)
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
        }
        .listStyle(.plain)
    }
}

struct SavedSpotCard: View {
    let spot: PlanSpot
    let index: Int
    let scheduledTime: String?

    var body: some View {
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
                    .lineLimit(1)

                Text(spot.formattedStayDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                openNavigation(to: spot)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 4)
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

struct SavedPlanMapView: View {
    let spots: [PlanSpot]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                Annotation(
                    spot.name,
                    coordinate: spot.coordinate,
                    anchor: .bottom
                ) {
                    SpotMarker(index: index + 1)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            fitMapToSpots()
        }
    }

    private func fitMapToSpots() {
        guard !spots.isEmpty else { return }

        let coordinates = spots.map { $0.coordinate }
        let minLat = coordinates.map(\.latitude).min() ?? 0
        let maxLat = coordinates.map(\.latitude).max() ?? 0
        let minLon = coordinates.map(\.longitude).min() ?? 0
        let maxLon = coordinates.map(\.longitude).max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5 + 0.01,
            longitudeDelta: (maxLon - minLon) * 1.5 + 0.01
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct SavedPlanListView: View {
    let spots: [PlanSpot]

    var body: some View {
        List {
            ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.name)
                            .font(.body)
                        Text(spot.formattedStayDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        openNavigation(to: spot)
                    } label: {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
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

#Preview {
    NavigationStack {
        FavoritesView()
    }
}
