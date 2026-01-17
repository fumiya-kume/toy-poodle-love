import SwiftUI

struct HeroSection: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // マスコットエリア
            ZStack {
                Circle()
                    .fill(AppTheme.secondaryColor)
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 10, y: 5)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.primaryColor)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .onAppear { isAnimating = true }

            // アプリ名
            Text("Toy Poodle Love")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.accentColor)

            // タグライン
            Text("愛犬とのお散歩をもっと楽しく")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HeroSection()
}
