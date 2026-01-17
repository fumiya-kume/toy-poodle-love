import Foundation
import MapKit

protocol LocationCompleterServiceProtocol: AnyObject {
    var suggestions: [SearchSuggestion] { get }
    var onSuggestionsUpdated: (([SearchSuggestion]) -> Void)? { get set }

    func updateQuery(_ query: String)
    func setRegion(_ region: MKCoordinateRegion)
    func search(suggestion: SearchSuggestion) async throws -> [Place]
    func clear()
}

final class LocationCompleterService: NSObject, LocationCompleterServiceProtocol, @unchecked Sendable {
    private let completer = MKLocalSearchCompleter()
    private(set) var suggestions: [SearchSuggestion] = []
    var onSuggestionsUpdated: (([SearchSuggestion]) -> Void)?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    func updateQuery(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            onSuggestionsUpdated?([])
            return
        }
        completer.queryFragment = query
    }

    func setRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func search(suggestion: SearchSuggestion) async throws -> [Place] {
        let request = MKLocalSearch.Request(completion: suggestion.toSearchCompletion())
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.map { Place(mapItem: $0) }
    }

    func clear() {
        completer.queryFragment = ""
        suggestions = []
        onSuggestionsUpdated?([])
    }
}

extension LocationCompleterService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let newSuggestions = completer.results.map { SearchSuggestion(completion: $0) }
        Task { @MainActor in
            self.suggestions = newSuggestions
            self.onSuggestionsUpdated?(newSuggestions)
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
            self.onSuggestionsUpdated?([])
        }
    }
}
