import SwiftUI

/// シナリオ生成タブ
struct ScenarioGenerateTab: View {
    @Environment(AppState.self) private var appState
    @State private var newSpotName = ""
    @State private var newSpotDescription = ""
    @State private var newSpotPoint = ""
    @State private var newSpotType: RouteSpotType = .waypoint

    private var state: ScenarioWriterState {
        appState.scenarioWriterState
    }

    var body: some View {
        @Bindable var bindableState = appState.scenarioWriterState

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("入力") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("ルート名") {
                            TextField("例: 東京観光ルート", text: $bindableState.scenarioRouteName)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("言語 (任意)") {
                            TextField("例: ja", text: $bindableState.scenarioLanguage)
                                .textFieldStyle(.roundedBorder)
                        }

                        Text("シナリオを生成するスポット")
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("スポット名", text: $newSpotName)
                                    .textFieldStyle(.roundedBorder)
                                Picker("タイプ", selection: $newSpotType) {
                                    ForEach(RouteSpotType.allCases) { spotType in
                                        Text(spotType.displayName).tag(spotType)
                                    }
                                }
                                .pickerStyle(.menu)
                                Button("追加") {
                                    state.addScenarioSpot(
                                        name: newSpotName,
                                        type: newSpotType,
                                        description: newSpotDescription,
                                        point: newSpotPoint
                                    )
                                    newSpotName = ""
                                    newSpotDescription = ""
                                    newSpotPoint = ""
                                    newSpotType = .waypoint
                                }
                                .disabled(newSpotName.isEmpty)
                            }

                            TextField("説明 (任意)", text: $newSpotDescription)
                                .textFieldStyle(.roundedBorder)
                            TextField("ポイント (任意)", text: $newSpotPoint)
                                .textFieldStyle(.roundedBorder)
                        }

                        if !state.scenarioSpots.isEmpty {
                            List {
                                ForEach(Array(state.scenarioSpots.enumerated()), id: \.offset) { index, spot in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(spot.name)
                                                .font(.headline)
                                            Text(spot.type.displayName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if let description = spot.description, !description.isEmpty {
                                                Text(description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let point = spot.point, !point.isEmpty {
                                                Text(point)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Button {
                                            state.removeScenarioSpot(at: index)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(height: min(CGFloat(state.scenarioSpots.count * 60), 240))
                        }

                        Picker("モデル", selection: $bindableState.scenarioModels) {
                            ForEach(ScenarioModels.allCases) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button("シナリオ生成") {
                            Task {
                                await state.generateScenario()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            state.scenarioRouteName.isEmpty ||
                            state.scenarioSpots.isEmpty ||
                            state.isLoadingScenario
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("結果") {
                    if state.isLoadingScenario {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "シナリオ生成中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.scenarioResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(result.routeName)
                                    .font(.headline)
                                Spacer()

                                if state.isLoadingScenarioIntegrate {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Button("シナリオを統合") {
                                        Task {
                                            await state.integrateScenarios()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }

                            Text("生成日時: \(result.generatedAt)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("成功: \(result.stats.successCount) / \(result.stats.totalSpots)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("処理時間: \(result.stats.processingTimeMs)ms")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(state.displayScenarios) { scenario in
                                SpotScenarioRow(
                                    spot: scenario,
                                    canInteract: appState.hasVideoPlayers,
                                    onDisplay: {
                                        appState.subtitleState.show(scenario.displayScenario)
                                    },
                                    onSpeak: {
                                        appState.ttsController.speak(scenario.displayScenario)
                                    }
                                )
                                Divider()
                            }

                            // TTS制御バー
                            if appState.ttsController.isSpeaking {
                                TTSControlBar()
                                    .padding(.top, 8)
                            }
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
    ScenarioGenerateTab()
        .environment(AppState())
        .frame(width: 500, height: 800)
}
