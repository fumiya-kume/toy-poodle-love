import SwiftUI
import SwiftData

struct PlanResultView: View {
    @Bindable var viewModel: PlanGeneratorViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Picker("表示モード", selection: $viewModel.viewMode) {
                ForEach(PlanGeneratorViewModel.ViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            contentView

            actionBar
        }
        .sheet(isPresented: $viewModel.showSpotDetailSheet) {
            if let spot = viewModel.selectedSpotForDetail {
                SpotDetailSheet(
                    spot: spot,
                    onToggleFavorite: {
                        viewModel.toggleFavorite(for: spot)
                    },
                    onNavigate: {
                        openNavigation(to: spot)
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $viewModel.showAddSpotSheet) {
            SpotSearchSheet(onSelect: { place in
                viewModel.addSpot(place)
            })
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            if viewModel.isEditingTitle {
                HStack {
                    TextField("タイトル", text: $viewModel.editedTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("保存") {
                        viewModel.saveTitle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            } else {
                Button {
                    viewModel.startEditingTitle()
                } label: {
                    HStack {
                        Text(viewModel.generatedPlan?.title ?? "プラン")
                            .font(.headline)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                Label(viewModel.generatedPlan?.formattedTotalDuration ?? "-", systemImage: "clock")
                Label(viewModel.generatedPlan?.formattedTotalDistance ?? "-", systemImage: "car")
                Label("\(viewModel.generatedSpots.count)箇所", systemImage: "mappin")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewMode {
        case .timeline:
            PlanTimelineView(viewModel: viewModel)
        case .map:
            PlanMapView(viewModel: viewModel)
        case .list:
            PlanListView(viewModel: viewModel)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.savePlan(context: modelContext)
                viewModel.saveFavoriteSpots(context: modelContext)
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.showAddSpotSheet = true
            } label: {
                Label("追加", systemImage: "plus")
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.openInAppleMaps()
            } label: {
                Label("地図で開く", systemImage: "map")
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.reset()
            } label: {
                Label("再生成", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
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
    PlanResultView(viewModel: PlanGeneratorViewModel())
}
