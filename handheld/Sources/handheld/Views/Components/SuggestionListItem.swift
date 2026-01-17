import SwiftUI

struct SuggestionListItem: View {
    let suggestion: SearchSuggestion

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CategoryIconView(category: suggestion.category, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                highlightedText(
                    text: suggestion.title,
                    ranges: suggestion.titleHighlightRanges
                )
                .font(.body)
                .lineLimit(1)

                subtitleView
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let formattedDistance = suggestion.formattedDistance {
            if !suggestion.subtitle.isEmpty {
                Text("\(formattedDistance)・\(suggestion.subtitle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text(formattedDistance)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        } else if !suggestion.subtitle.isEmpty {
            highlightedText(
                text: suggestion.subtitle,
                ranges: suggestion.subtitleHighlightRanges
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
    }

    private func highlightedText(text: String, ranges: [NSRange]) -> Text {
        guard !ranges.isEmpty else {
            return Text(text)
        }

        var result = Text("")
        var currentIndex = text.startIndex

        for range in ranges.sorted(by: { $0.location < $1.location }) {
            guard let rangeStart = text.index(text.startIndex, offsetBy: range.location, limitedBy: text.endIndex),
                  let rangeEnd = text.index(rangeStart, offsetBy: range.length, limitedBy: text.endIndex) else {
                continue
            }

            if currentIndex < rangeStart {
                result = result + Text(text[currentIndex..<rangeStart])
            }

            result = result + Text(text[rangeStart..<rangeEnd]).bold()

            currentIndex = rangeEnd
        }

        if currentIndex < text.endIndex {
            result = result + Text(text[currentIndex..<text.endIndex])
        }

        return result
    }
}
