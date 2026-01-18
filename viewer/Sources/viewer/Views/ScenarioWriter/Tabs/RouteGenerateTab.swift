import SwiftUI

/// ルート生成（AIでスポット生成）タブ
struct RouteGenerateTab: View {
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
                            TextField("例: 東京駅", text: $bindableState.routeGenerateStartPoint)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("目的・テーマ") {
                            TextField("例: 皇居周辺の観光スポットを巡りたい", text: $bindableState.routeGeneratePurpose)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("生成地点数") {
                            Stepper(
                                "\(state.routeGenerateSpotCount)箇所",
                                value: $bindableState.routeGenerateSpotCount,
                                in: 3...8
                            )
                        }

                        ModelPickerView(selection: $bindableState.routeGenerateModel)

                        Button("AIでルート生成") {
                            Task {
                                await state.generateRoute()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            state.routeGenerateStartPoint.isEmpty ||
                            state.routeGeneratePurpose.isEmpty ||
                            state.isLoadingRouteGenerate
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("結果") {
                    if state.isLoadingRouteGenerate {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "ルート生成中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.routeGenerateResult {
                        VStack(alignment: .leading, spacing: 8) {
                            if let model = result.model {
                                Text("生成モデル: \(model)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("生成されたスポット")
                                .font(.headline)

                            ForEach(Array(result.spots.enumerated()), id: \.offset) { index, spot in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24, alignment: .trailing)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(spot.name)
                                                .font(.headline)
                                            Text(RouteSpotType.fromGeneratedType(spot.type).displayName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if let description = spot.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 28)
                                    }
                                    if let note = spot.generatedNote {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 28)
                                    }
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }

                            Button("このスポットでシナリオを生成") {
                                state.createSpotsFromRouteGeneration()
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
    RouteGenerateTab()
        .environment(AppState())
        .frame(width: 500, height: 700)
}
