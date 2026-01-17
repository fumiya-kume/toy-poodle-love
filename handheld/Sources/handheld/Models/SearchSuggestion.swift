import Foundation
import MapKit

struct SearchSuggestion: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let titleHighlightRanges: [NSRange]
    let subtitleHighlightRanges: [NSRange]
    private let completion: MKLocalSearchCompletion

    init(completion: MKLocalSearchCompletion) {
        self.id = UUID()
        self.title = completion.title
        self.subtitle = completion.subtitle
        self.titleHighlightRanges = completion.titleHighlightRanges.map { $0.rangeValue }
        self.subtitleHighlightRanges = completion.subtitleHighlightRanges.map { $0.rangeValue }
        self.completion = completion
    }

    func toSearchCompletion() -> MKLocalSearchCompletion {
        completion
    }

    static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}
