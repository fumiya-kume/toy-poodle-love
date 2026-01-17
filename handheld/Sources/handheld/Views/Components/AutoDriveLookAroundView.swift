import SwiftUI
import MapKit

struct AutoDriveLookAroundView: View {
    let scene: MKLookAroundScene?
    let isLoading: Bool
    let pointIndex: Int
    let totalPoints: Int

    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if let scene = scene {
                lookAroundContent(scene: scene)
            } else {
                unavailableView
            }

            indexOverlay
        }
        .animation(.easeInOut(duration: 0.3), value: pointIndex)
    }

    private var loadingView: some View {
        ProgressView("読み込み中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
    }

    private func lookAroundContent(scene: MKLookAroundScene) -> some View {
        LookAroundPreview(initialScene: scene)
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 1.1).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                )
            )
            .id(pointIndex)
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            "Look Around利用不可",
            systemImage: "eye.slash",
            description: Text("この地点ではLook Aroundを利用できません。次の地点に自動的に進みます。")
        )
    }

    private var indexOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(pointIndex + 1) / \(totalPoints)")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }
            .padding()

            Spacer()
        }
    }
}
