import Foundation
import MapKit

protocol LocationSearchServiceProtocol {
    func search(query: String, region: MKCoordinateRegion?) async throws -> [Place]
}

final class LocationSearchService: LocationSearchServiceProtocol {
    func search(query: String, region: MKCoordinateRegion?) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let region = region {
            request.region = region
        }

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        return response.mapItems.map { Place(mapItem: $0) }
    }
}
