import SwiftUI
import UIKit

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.primaryColor)
                .frame(width: 50, height: 50)
                .background(AppTheme.secondaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        FeatureCard(
            icon: "magnifyingglass",
            title: "場所を検索",
            description: "お散歩コースを探しましょう"
        )

        FeatureCard(
            icon: "heart.fill",
            title: "お気に入り",
            description: "保存した場所を確認"
        )
    }
    .padding()
}
