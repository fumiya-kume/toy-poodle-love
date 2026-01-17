import Foundation
import MapKit

struct SearchSuggestion: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let titleHighlightRanges: [NSRange]
    let subtitleHighlightRanges: [NSRange]
    let category: SuggestionCategory
    var coordinate: CLLocationCoordinate2D?
    var distance: CLLocationDistance?
    private let completion: MKLocalSearchCompletion

    init(completion: MKLocalSearchCompletion) {
        self.id = UUID()
        self.title = completion.title
        self.subtitle = completion.subtitle
        self.titleHighlightRanges = completion.titleHighlightRanges.map { $0.rangeValue }
        self.subtitleHighlightRanges = completion.subtitleHighlightRanges.map { $0.rangeValue }
        self.completion = completion
        self.category = SuggestionCategoryClassifier.classify(
            title: completion.title,
            subtitle: completion.subtitle
        )
        self.coordinate = nil
        self.distance = nil
    }

    func toSearchCompletion() -> MKLocalSearchCompletion {
        completion
    }

    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}
