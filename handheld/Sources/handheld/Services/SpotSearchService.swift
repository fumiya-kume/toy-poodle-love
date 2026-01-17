import Foundation
import MapKit
import os

protocol SpotSearchServiceProtocol {
    func searchSpots(
        theme: String,
        categories: [PlanCategory],
        centerCoordinate: CLLocationCoordinate2D,
        radius: SearchRadius
    ) async throws -> [Place]
}

final class SpotSearchService: SpotSearchServiceProtocol {
    private let locationSearchService: LocationSearchServiceProtocol

    init(locationSearchService: LocationSearchServiceProtocol = LocationSearchService()) {
        self.locationSearchService = locationSearchService
    }

    func searchSpots(
        theme: String,
        categories: [PlanCategory],
        centerCoordinate: CLLocationCoordinate2D,
        radius: SearchRadius
    ) async throws -> [Place] {
        AppLogger.search.info("スポット検索を開始: テーマ=\(theme), カテゴリ数=\(categories.count)")

        let region = MKCoordinateRegion(
            center: centerCoordinate,
            latitudinalMeters: radius.meters * 2,
            longitudinalMeters: radius.meters * 2
        )

        var queries: [String] = []

        queries.append(theme)

        for category in categories {
            for keyword in category.searchKeywords {
                queries.append("\(theme) \(keyword)")
            }
        }

        var allPlaces: [Place] = []
        var seenCoordinates: Set<String> = []

        try await withThrowingTaskGroup(of: [Place].self) { group in
            for query in queries {
                group.addTask {
                    do {
                        return try await self.locationSearchService.search(query: query, region: region)
                    } catch {
                        AppLogger.search.warning("クエリ '\(query)' の検索に失敗: \(error.localizedDescription)")
                        return []
                    }
                }
            }

            for try await places in group {
                for place in places {
                    let coordinateKey = "\(place.coordinate.latitude),\(place.coordinate.longitude)"

                    if !seenCoordinates.contains(coordinateKey) {
                        let distance = centerCoordinate.distance(to: place.coordinate)
                        if distance <= radius.meters {
                            seenCoordinates.insert(coordinateKey)
                            allPlaces.append(place)
                        }
                    }
                }
            }
        }

        AppLogger.search.info("スポット検索完了: \(allPlaces.count)件の候補を発見")
        return allPlaces
    }
}
