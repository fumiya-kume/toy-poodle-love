import SwiftUI

/// ルート最適化タブ
struct RouteOptimizeTab: View {
    @Environment(AppState.self) private var appState
    @State private var newWaypointAddress = ""

    private var state: ScenarioWriterState {
        appState.scenarioWriterState
    }

    var body: some View {
        @Bindable var bindableState = appState.scenarioWriterState

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("入力") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("移動モード", selection: $bindableState.selectedTravelMode) {
                            ForEach(TravelMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("順序最適化", isOn: $bindableState.optimizeWaypointOrder)

                        Text("ウェイポイント")
                            .font(.caption)

                        HStack {
                            TextField("住所を入力", text: $newWaypointAddress)
                                .textFieldStyle(.roundedBorder)
                            Button("追加") {
                                state.addWaypoint(newWaypointAddress)
                                newWaypointAddress = ""
                            }
                            .disabled(newWaypointAddress.isEmpty)
                        }

                        if !state.routeWaypoints.isEmpty {
                            List {
                                ForEach(Array(state.routeWaypoints.enumerated()), id: \.offset) { index, waypoint in
                                    HStack {
                                        let label = waypoint.address ?? waypoint.name ?? waypoint.placeId ?? "不明"
                                        Text("\(index + 1). \(label)")
                                        Spacer()
                                        Button {
                                            state.removeWaypoint(at: index)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(height: min(CGFloat(state.routeWaypoints.count * 44), 200))
                        }

                        Button("ルート最適化") {
                            Task {
                                await state.optimizeRoute()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(state.routeWaypoints.count < 2 || state.isLoadingRouteOptimize)
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("結果") {
                    if state.isLoadingRouteOptimize {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "最適化中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.routeOptimizeResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最適化されたルート")
                                .font(.headline)

                            ForEach(Array(result.optimizedRoute.orderedWaypoints.enumerated()), id: \.offset) { index, optimized in
                                HStack {
                                    Text("\(index + 1).")
                                        .foregroundColor(.secondary)
                                    let label = optimized.waypoint.address ?? optimized.waypoint.name ?? optimized.waypoint.placeId ?? "不明"
                                    Text(label)
                                }
                            }

                            Text("総距離: \(Double(result.optimizedRoute.totalDistanceMeters) / 1000, specifier: "%.1f") km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let minutes = result.optimizedRoute.totalDurationSeconds / 60
                            Text("所要時間: \(minutes)分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("結果がありません")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    RouteOptimizeTab()
        .environment(AppState())
        .frame(width: 500, height: 600)
}
