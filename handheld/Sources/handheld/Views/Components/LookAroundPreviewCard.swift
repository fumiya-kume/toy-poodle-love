import SwiftUI
import MapKit

struct LookAroundPreviewCard: View {
    let scene: MKLookAroundScene?
    let locationName: String
    let isLoading: Bool
    var onTap: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(locationName, systemImage: "binoculars.fill")
                    .font(.caption.bold())
                    .lineLimit(1)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("閉じる")
            }

            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let scene = scene {
                    LookAroundPreview(initialScene: scene)
                } else {
                    ContentUnavailableView(
                        "利用不可",
                        systemImage: "eye.slash",
                        description: Text("この地点ではLook Aroundを利用できません")
                    )
                    .font(.caption)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .frame(width: 240, height: 150)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .onTapGesture {
            if scene != nil {
                onTap()
            }
        }
        .accessibilityLabel("Look Aroundプレビュー: \(locationName)")
        .accessibilityHint("タップして拡大表示")
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        VStack(spacing: 20) {
            LookAroundPreviewCard(
                scene: nil,
                locationName: "東京タワー",
                isLoading: true,
                onTap: {},
                onClose: {}
            )

            LookAroundPreviewCard(
                scene: nil,
                locationName: "東京タワー",
                isLoading: false,
                onTap: {},
                onClose: {}
            )
        }
    }
}
