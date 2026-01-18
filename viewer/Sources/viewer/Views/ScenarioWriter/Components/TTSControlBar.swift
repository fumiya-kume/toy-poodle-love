import SwiftUI

/// TTS の再生制御バー
struct TTSControlBar: View {
    @Environment(AppState.self) private var appState

    private var tts: TTSController {
        appState.ttsController
    }

    var body: some View {
        HStack(spacing: 16) {
            if tts.isSpeaking {
                if tts.isPaused {
                    Button {
                        tts.resume()
                    } label: {
                        Label("再開", systemImage: "play.fill")
                    }
                } else {
                    Button {
                        tts.pause()
                    } label: {
                        Label("一時停止", systemImage: "pause.fill")
                    }
                }

                Button {
                    tts.stop()
                } label: {
                    Label("停止", systemImage: "stop.fill")
                }
            }
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    TTSControlBar()
        .environment(AppState())
        .padding()
}
