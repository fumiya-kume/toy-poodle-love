import SwiftUI

/// スポットシナリオを表示する行（表示/再生ボタン付き）
struct SpotScenarioRow: View {
    let spot: SpotScenario
    let canInteract: Bool
    let onDisplay: () -> Void
    let onSpeak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.headline)
                    Text(RouteSpotType(rawValue: spot.type)?.displayName ?? spot.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        onDisplay()
                    } label: {
                        Label("表示", systemImage: "text.bubble")
                    }
                    .disabled(!canInteract)
                    .help(canInteract ? "字幕として表示" : "Video Playerを開いてください")

                    Button {
                        onSpeak()
                    } label: {
                        Label("再生", systemImage: "speaker.wave.2")
                    }
                    .disabled(!canInteract)
                    .help(canInteract ? "TTSで読み上げ" : "Video Playerを開いてください")
                }
                .buttonStyle(.bordered)
            }

            Text(spot.displayScenario)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)

            if spot.error != nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("エラーが含まれています")
                }
                .font(.caption2)
                .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SpotScenarioRow(
        spot: SpotScenario(
            name: "東京タワー",
            type: "waypoint",
            gemini: "東京タワーは、1958年に完成した高さ333mの電波塔です。",
            qwen: nil,
            error: nil
        ),
        canInteract: true,
        onDisplay: {},
        onSpeak: {}
    )
    .padding()
}
