import SwiftUI

/// テキスト生成タブ
struct TextGenerationTab: View {
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
                        ModelPickerView(selection: $bindableState.selectedTextModel)

                        Text("プロンプト")
                            .font(.caption)
                        TextEditor(text: $bindableState.textGenerationPrompt)
                            .frame(minHeight: 100)
                            .font(.body)

                        Button("生成") {
                            Task {
                                await state.generateText()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(state.textGenerationPrompt.isEmpty || state.isLoadingTextGeneration)
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("結果") {
                    if state.isLoadingTextGeneration {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "生成中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.textGenerationResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.response)
                                .font(.body)
                                .textSelection(.enabled)

                            Divider()

                            Text("モデル: \(state.selectedTextModel.rawValue)")
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
    TextGenerationTab()
        .environment(AppState())
        .frame(width: 500, height: 600)
}
