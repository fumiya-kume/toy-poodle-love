import SwiftUI

/// ジオコーディングタブ
struct GeocodeTab: View {
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
                        Text("住所（1行に1つ）")
                            .font(.caption)
                        TextEditor(text: $bindableState.geocodeAddresses)
                            .frame(minHeight: 100)
                            .font(.body)

                        Button("ジオコーディング") {
                            Task {
                                await state.geocode()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(state.geocodeAddresses.isEmpty || state.isLoadingGeocode)
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("結果") {
                    if state.isLoadingGeocode {
                        HStack {
                            Spacer()
                            LoadingOverlay(message: "ジオコーディング中...")
                            Spacer()
                        }
                        .padding()
                    } else if let result = state.geocodeResult {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(result.places) { place in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.inputAddress)
                                        .font(.headline)
                                    Text("緯度: \(place.location.latitude, specifier: "%.6f")")
                                        .font(.caption)
                                    Text("経度: \(place.location.longitude, specifier: "%.6f")")
                                        .font(.caption)
                                    Text("住所: \(place.formattedAddress)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                Divider()
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
    GeocodeTab()
        .environment(AppState())
        .frame(width: 500, height: 600)
}
