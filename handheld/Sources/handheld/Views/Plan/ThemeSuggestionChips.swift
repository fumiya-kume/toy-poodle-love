import SwiftUI

struct ThemeSuggestionChips: View {
    let categories: Set<PlanCategory>
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(categories)) { category in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                        Text(category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(category.suggestions, id: \.self) { suggestion in
                            Button {
                                onSelect(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background {
                                        Capsule()
                                            .fill(Color(.tertiarySystemBackground))
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

#Preview {
    ThemeSuggestionChips(
        categories: [.scenic, .activity],
        onSelect: { suggestion in
            print("Selected: \(suggestion)")
        }
    )
    .padding()
}
