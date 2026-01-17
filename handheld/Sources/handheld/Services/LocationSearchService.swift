import Foundation
import MapKit
import os

protocol LocationSearchServiceProtocol {
    func search(query: String, region: MKCoordinateRegion?) async throws -> [Place]
}

final class LocationSearchService: LocationSearchServiceProtocol {
    func search(query: String, region: MKCoordinateRegion?) async throws -> [Place] {
        AppLogger.search.info("検索を開始します: \(query)")

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let region = region {
            request.region = region
        }

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            let places = response.mapItems.map { Place(mapItem: $0) }
            AppLogger.search.info("検索完了: \(places.count)件の結果")
            return places
        } catch {
            AppLogger.search.error("検索に失敗しました: \(error.localizedDescription)")
            throw AppError.searchFailed(underlying: error)
        }
    }
}
