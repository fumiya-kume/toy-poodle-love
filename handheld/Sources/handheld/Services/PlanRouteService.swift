import Foundation
import MapKit
import os

struct SpotRoute {
    let fromSpotIndex: Int
    let toSpotIndex: Int
    let route: Route
}

/// ルート計算結果（失敗情報含む）
struct RouteCalculationResult {
    let routes: [SpotRoute]
    let failures: [RouteFailure]

    var hasPartialFailure: Bool {
        !failures.isEmpty && !routes.isEmpty
    }

    var allSucceeded: Bool {
        failures.isEmpty
    }
}

/// ルート計算失敗情報
struct RouteFailure {
    let fromSpotIndex: Int
    let toSpotIndex: Int
    let fromSpotName: String
    let toSpotName: String
    let error: Error
}

protocol PlanRouteServiceProtocol {
    func calculateRoutes(for spots: [PlanSpot]) async throws -> RouteCalculationResult
    func calculateTotalMetrics(from routes: [SpotRoute], spots: [PlanSpot]) -> (totalDistance: Double, totalDuration: TimeInterval)
    func updateSpotRouteInfo(spots: inout [PlanSpot], routes: [SpotRoute])
}

final class PlanRouteService: PlanRouteServiceProtocol {
    private let directionsService: DirectionsServiceProtocol

    init(directionsService: DirectionsServiceProtocol = DirectionsService()) {
        self.directionsService = directionsService
    }

    func calculateRoutes(for spots: [PlanSpot]) async throws -> RouteCalculationResult {
        guard spots.count >= 2 else {
            AppLogger.directions.info("スポットが2件未満のためルート計算をスキップ")
            return RouteCalculationResult(routes: [], failures: [])
        }

        AppLogger.directions.info("ルート計算を開始: \(spots.count)件のスポット")

        var spotRoutes: [SpotRoute] = []
        var failures: [RouteFailure] = []

        // タスクグループの結果型
        enum RouteResult {
            case success(SpotRoute)
            case failure(RouteFailure)
        }

        await withTaskGroup(of: RouteResult.self) { group in
            for i in 0..<(spots.count - 1) {
                let fromSpot = spots[i]
                let toSpot = spots[i + 1]
                let fromIndex = i
                let toIndex = i + 1

                group.addTask {
                    do {
                        if let route = try await self.directionsService.calculateRoute(
                            from: fromSpot.coordinate,
                            to: toSpot.coordinate,
                            transportType: .automobile
                        ) {
                            return .success(SpotRoute(fromSpotIndex: fromIndex, toSpotIndex: toIndex, route: route))
                        }
                        // ルートが nil の場合もエラーとして扱う
                        let error = NSError(domain: "PlanRouteService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ルートが見つかりません"])
                        return .failure(RouteFailure(
                            fromSpotIndex: fromIndex,
                            toSpotIndex: toIndex,
                            fromSpotName: fromSpot.name,
                            toSpotName: toSpot.name,
                            error: error
                        ))
                    } catch {
                        return .failure(RouteFailure(
                            fromSpotIndex: fromIndex,
                            toSpotIndex: toIndex,
                            fromSpotName: fromSpot.name,
                            toSpotName: toSpot.name,
                            error: error
                        ))
                    }
                }
            }

            for await result in group {
                switch result {
                case .success(let spotRoute):
                    spotRoutes.append(spotRoute)
                case .failure(let failure):
                    failures.append(failure)
                    AppLogger.directions.warning("ルート計算に失敗 (\(failure.fromSpotName) → \(failure.toSpotName)): \(failure.error.localizedDescription)")
                }
            }
        }

        spotRoutes.sort { $0.fromSpotIndex < $1.fromSpotIndex }

        AppLogger.directions.info("ルート計算完了: 成功=\(spotRoutes.count), 失敗=\(failures.count)")
        return RouteCalculationResult(routes: spotRoutes, failures: failures)
    }

    func calculateTotalMetrics(from routes: [SpotRoute], spots: [PlanSpot]) -> (totalDistance: Double, totalDuration: TimeInterval) {
        var totalDistance: Double = 0
        var totalDuration: TimeInterval = 0

        for route in routes {
            totalDistance += route.route.distance
            totalDuration += route.route.expectedTravelTime
        }

        for spot in spots {
            totalDuration += spot.estimatedStayDuration
        }

        return (totalDistance, totalDuration)
    }

    func updateSpotRouteInfo(spots: inout [PlanSpot], routes: [SpotRoute]) {
        spots[0].routeDistanceFromPrevious = nil
        spots[0].routeTravelTimeFromPrevious = nil

        for route in routes {
            let toIndex = route.toSpotIndex
            if toIndex < spots.count {
                spots[toIndex].routeDistanceFromPrevious = route.route.distance
                spots[toIndex].routeTravelTimeFromPrevious = route.route.expectedTravelTime
            }
        }
    }
}
