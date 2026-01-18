import SwiftUI

/// 動画上に字幕を表示するオーバーレイ
struct SubtitleOverlayView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let text = appState.subtitleState.currentText {
            VStack {
                Spacer()
                Text(text)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity * 0.8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
            }
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        SubtitleOverlayView()
    }
    .environment(AppState())
    .frame(width: 800, height: 600)
}
