import Foundation
import MapKit
import os

/// スポット検索サービスのプロトコル。
///
/// テーマとカテゴリに基づいて周辺のスポットを検索します。
///
/// ## 概要
///
/// このプロトコルは、プラン生成時に使用するスポット候補を検索する機能を定義します。
/// 複数のキーワードで並列検索し、重複を除去して結果を返します。
///
/// ## 使用例
///
/// ```swift
/// let service: SpotSearchServiceProtocol = SpotSearchService()
/// let spots = try await service.searchSpots(
///     theme: "神社巡り",
///     categories: [.scenic],
///     centerCoordinate: coordinate,
///     radius: .large
/// )
/// ```
protocol SpotSearchServiceProtocol {
    /// スポットを検索する。
    ///
    /// - Parameters:
    ///   - theme: 検索テーマ
    ///   - categories: 検索カテゴリのリスト
    ///   - centerCoordinate: 検索中心座標
    ///   - radius: 検索半径
    ///
    /// - Returns: 検索結果のスポット配列
    ///
    /// - Throws: 検索に失敗した場合
    func searchSpots(
        theme: String,
        categories: [PlanCategory],
        centerCoordinate: CLLocationCoordinate2D,
        radius: SearchRadius
    ) async throws -> [Place]
}

/// スポット検索サービス。
///
/// ``SpotSearchServiceProtocol``の実装クラスです。
/// 複数のキーワードで並列検索し、重複を除去して結果を返します。
///
/// - SeeAlso: ``SpotSearchServiceProtocol``
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
