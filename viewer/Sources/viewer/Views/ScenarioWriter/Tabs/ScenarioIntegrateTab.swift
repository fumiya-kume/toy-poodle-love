import SwiftUI

/// シナリオ統合タブ（統合結果の表示専用）
struct ScenarioIntegrateTab: View {
    @Environment(AppState.self) private var appState

    private var state: ScenarioWriterState {
        appState.scenarioWriterState
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("統合シナリオ") {
                    if state.isLoadingScenarioIntegrate {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "シナリオ統合中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.scenarioIntegrationResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("AIによる統合シナリオ")
                                    .font(.headline)
                            }
                            .foregroundColor(.accentColor)

                            Text(result.routeName)
                                .font(.subheadline)
                            Text("統合日時: \(result.integratedAt)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("使用モデル: \(result.sourceModel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("統合LLM: \(result.integrationLLM)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("処理時間: \(result.processingTimeMs)ms")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Divider()

                            Text(result.integratedScript)
                                .font(.body)
                                .textSelection(.enabled)

                            HStack(spacing: 8) {
                                Button("表示") {
                                    appState.subtitleState.show(result.integratedScript)
                                }
                                Button("再生") {
                                    appState.ttsController.speak(result.integratedScript)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(!appState.hasVideoPlayers)
                            .help(appState.hasVideoPlayers ? "字幕またはTTSで出力" : "Video Playerを開いてください")

                            // TTS制御バー
                            if appState.ttsController.isSpeaking {
                                TTSControlBar()
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.vertical, 8)
                    } else if state.scenarioResult != nil {
                        VStack(spacing: 12) {
                            Text("シナリオ生成タブで「シナリオを統合」をクリックしてください")
                                .foregroundColor(.secondary)

                            Button("シナリオを統合") {
                                Task {
                                    await state.integrateScenarios()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        Text("まずシナリオ生成タブでシナリオを生成してください")
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
    ScenarioIntegrateTab()
        .environment(AppState())
        .frame(width: 500, height: 600)
}
