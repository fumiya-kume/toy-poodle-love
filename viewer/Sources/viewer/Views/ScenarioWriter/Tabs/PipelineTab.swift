import SwiftUI

/// パイプライン（E2Eルート生成〜最適化）タブ
struct PipelineTab: View {
    @Environment(AppState.self) private var appState

    private var state: ScenarioWriterState {
        appState.scenarioWriterState
    }

    var body: some View {
        @Bindable var bindableState = appState.scenarioWriterState

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("入力") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("出発地") {
                            TextField("例: 東京駅", text: $bindableState.pipelineStartPoint)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("目的・テーマ") {
                            TextField("例: 皇居周辺の観光スポットを巡りたい", text: $bindableState.pipelinePurpose)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("生成地点数") {
                            Stepper(
                                "\(state.pipelineSpotCount)箇所",
                                value: $bindableState.pipelineSpotCount,
                                in: 3...8
                            )
                        }

                        ModelPickerView(selection: $bindableState.pipelineModel, label: "AIモデル")

                        Button("パイプライン実行") {
                            Task {
                                await state.runPipeline()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            state.pipelineStartPoint.isEmpty ||
                            state.pipelinePurpose.isEmpty ||
                            state.isLoadingPipeline
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("結果") {
                    if state.isLoadingPipeline {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "パイプライン実行中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.pipelineResult {
                        VStack(alignment: .leading, spacing: 8) {
                            if let routeName = result.routeGeneration.routeName {
                                Text(routeName)
                                    .font(.headline)
                            }

                            if let spots = result.routeGeneration.spots {
                                Text("AIが生成したスポット")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(Array(spots.enumerated()), id: \.offset) { index, spot in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24, alignment: .trailing)
                                        VStack(alignment: .leading) {
                                            Text(spot.name)
                                                .fontWeight(.medium)
                                            if let description = spot.description {
                                                Text(description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()

                            if let optimization = result.routeOptimization.orderedWaypoints,
                               !optimization.isEmpty {
                                Text("最適化されたルート順序")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(Array(optimization.enumerated()), id: \.offset) { index, waypoint in
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24, alignment: .trailing)
                                        Text(waypoint.waypoint.name ?? waypoint.waypoint.address ?? "不明")
                                    }
                                }
                            }

                            Divider()

                            HStack {
                                if let distance = result.routeOptimization.totalDistanceMeters {
                                    Text("総距離: \(Double(distance) / 1000, specifier: "%.1f") km")
                                }
                                if let duration = result.routeOptimization.totalDurationSeconds {
                                    let minutes = duration / 60
                                    Text("所要時間: \(minutes)分")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)

                            Text("処理時間: \(result.totalProcessingTimeMs)ms")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Divider()

                            Button("このルートでシナリオを生成") {
                                state.createSpotsFromPipeline()
                            }
                            .buttonStyle(.bordered)
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
    PipelineTab()
        .environment(AppState())
        .frame(width: 500, height: 700)
}
