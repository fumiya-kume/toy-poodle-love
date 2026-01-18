import SwiftUI

/// ローディング表示用のオーバーレイ
struct LoadingOverlay: View {
    var message: String = "読み込み中..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    LoadingOverlay()
}
