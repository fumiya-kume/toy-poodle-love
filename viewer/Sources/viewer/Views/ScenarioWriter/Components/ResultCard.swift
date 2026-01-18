import SwiftUI

/// 結果表示用のカード
struct ResultCard<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            content()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    ResultCard(title: "テスト結果") {
        Text("これはテスト用の内容です。")
    }
    .padding()
}
