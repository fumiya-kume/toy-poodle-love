import SwiftUI

struct GeneratingProgressView: View {
    let state: PlanGeneratorState

    private let steps = [
        ("スポット検索中", "magnifyingglass"),
        ("AI生成中", "wand.and.stars"),
        ("ルート計算中", "map")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(state.progressMessage)
                    .font(.headline)
            }

            VStack(spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(stepColor(for: index + 1))
                                .frame(width: 32, height: 32)

                            if state.progressStep > index + 1 {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: step.1)
                                    .font(.caption)
                                    .foregroundStyle(state.progressStep >= index + 1 ? .white : .secondary)
                            }
                        }

                        Text(step.0)
                            .foregroundStyle(state.progressStep >= index + 1 ? .primary : .secondary)

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .padding()
    }

    private func stepColor(for step: Int) -> Color {
        if state.progressStep > step {
            return .green
        } else if state.progressStep == step {
            return .accentColor
        } else {
            return Color.secondary.opacity(0.3)
        }
    }
}

#Preview {
    VStack {
        GeneratingProgressView(state: .searchingSpots)
        GeneratingProgressView(state: .generatingPlan)
        GeneratingProgressView(state: .calculatingRoutes)
    }
}
