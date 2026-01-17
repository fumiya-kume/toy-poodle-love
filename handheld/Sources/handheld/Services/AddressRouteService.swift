import CoreLocation
import Foundation
import MapKit
import os

/// 住所間のルートセグメントを表すモデル
struct RouteSegment: Identifiable {
    let id: UUID
    let fromPlace: GeocodedPlace
    let toPlace: GeocodedPlace
    let route: Route

    init(fromPlace: GeocodedPlace, toPlace: GeocodedPlace, route: Route) {
        self.id = UUID()
        self.fromPlace = fromPlace
        self.toPlace = toPlace
        self.route = route
    }
}

/// 住所リストから計算された全体のルート結果
struct AddressRouteResult {
    let places: [GeocodedPlace]
    let segments: [RouteSegment]
    let failedSegments: [(from: GeocodedPlace, to: GeocodedPlace, error: Error)]

    var totalDistance: CLLocationDistance {
        segments.reduce(0) { $0 + $1.route.distance }
    }

    var totalTravelTime: TimeInterval {
        segments.reduce(0) { $0 + $1.route.expectedTravelTime }
    }

    var formattedTotalDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1f km", totalDistance / 1000)
        } else {
            return String(format: "%.0f m", totalDistance)
        }
    }

    var formattedTotalTravelTime: String {
        let hours = Int(totalTravelTime) / 3600
        let minutes = Int(totalTravelTime) % 3600 / 60

        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var hasAllSegmentsSucceeded: Bool {
        failedSegments.isEmpty
    }

    var allPolylines: [MKPolyline] {
        segments.map { $0.route.polyline }
    }
}

protocol AddressRouteServiceProtocol {
    /// 住所リストからルートを計算する
    /// - Parameters:
    ///   - addresses: 住所のリスト（順番通りにルートを計算）
    ///   - transportType: 移動手段（徒歩または車）
    /// - Returns: ルート計算結果
    func calculateRoute(
        from addresses: [String],
        transportType: TransportType
    ) async throws -> AddressRouteResult

    /// ジオコーディング済みの場所リストからルートを計算する
    /// - Parameters:
    ///   - places: ジオコーディング済みの場所リスト
    ///   - transportType: 移動手段
    /// - Returns: ルート計算結果
    func calculateRoute(
        from places: [GeocodedPlace],
        transportType: TransportType
    ) async throws -> AddressRouteResult
}

final class AddressRouteService: AddressRouteServiceProtocol {
    private let geocodingService: GeocodingServiceProtocol
    private let directionsService: DirectionsServiceProtocol

    init(
        geocodingService: GeocodingServiceProtocol = GeocodingService(),
        directionsService: DirectionsServiceProtocol = DirectionsService()
    ) {
        self.geocodingService = geocodingService
        self.directionsService = directionsService
    }

    func calculateRoute(
        from addresses: [String],
        transportType: TransportType
    ) async throws -> AddressRouteResult {
        AppLogger.directions.info("住所リストからルート計算を開始: \(addresses.count)件の住所")

        guard addresses.count >= 2 else {
            AppLogger.directions.warning("ルート計算には少なくとも2つの住所が必要です")
            throw AppError.invalidCoordinates
        }

        // Step 1: 住所をジオコーディング
        let places = try await geocodingService.geocodeMultiple(addresses: addresses)

        guard places.count >= 2 else {
            AppLogger.directions.warning("ジオコーディングに成功した住所が2件未満です")
            throw AppError.searchNoResults
        }

        // Step 2: ルートを計算
        return try await calculateRoute(from: places, transportType: transportType)
    }

    func calculateRoute(
        from places: [GeocodedPlace],
        transportType: TransportType
    ) async throws -> AddressRouteResult {
        AppLogger.directions.info("\(places.count)件の場所間のルートを計算開始")

        guard places.count >= 2 else {
            throw AppError.invalidCoordinates
        }

        var segments: [RouteSegment] = []
        var failedSegments: [(from: GeocodedPlace, to: GeocodedPlace, error: Error)] = []

        // 各地点間のルートを順番に計算
        for index in 0..<(places.count - 1) {
            let fromPlace = places[index]
            let toPlace = places[index + 1]

            do {
                let route = try await directionsService.calculateRoute(
                    from: fromPlace.coordinate,
                    to: toPlace.coordinate,
                    transportType: transportType
                )

                if let route = route {
                    let segment = RouteSegment(
                        fromPlace: fromPlace,
                        toPlace: toPlace,
                        route: route
                    )
                    segments.append(segment)
                    AppLogger.directions.info(
                        "ルートセグメント計算完了: \(fromPlace.originalAddress) → \(toPlace.originalAddress)"
                    )
                } else {
                    let error = AppError.noRouteFound
                    failedSegments.append((from: fromPlace, to: toPlace, error: error))
                    AppLogger.directions.warning(
                        "ルートが見つかりませんでした: \(fromPlace.originalAddress) → \(toPlace.originalAddress)"
                    )
                }
            } catch {
                failedSegments.append((from: fromPlace, to: toPlace, error: error))
                AppLogger.directions.error(
                    "ルート計算に失敗: \(fromPlace.originalAddress) → \(toPlace.originalAddress): \(error.localizedDescription)"
                )
            }
        }

        let result = AddressRouteResult(
            places: places,
            segments: segments,
            failedSegments: failedSegments
        )

        AppLogger.directions.info(
            "ルート計算完了: \(segments.count)セグメント成功, \(failedSegments.count)セグメント失敗, 総距離: \(result.formattedTotalDistance), 総時間: \(result.formattedTotalTravelTime)"
        )

        return result
    }
}
