import Foundation
import MapKit
import os

struct SpotRoute {
    let fromSpotIndex: Int
    let toSpotIndex: Int
    let route: Route
}

protocol PlanRouteServiceProtocol {
    func calculateRoutes(for spots: [PlanSpot]) async throws -> [SpotRoute]
    func calculateTotalMetrics(from routes: [SpotRoute], spots: [PlanSpot]) -> (totalDistance: Double, totalDuration: TimeInterval)
    func updateSpotRouteInfo(spots: inout [PlanSpot], routes: [SpotRoute])
}

final class PlanRouteService: PlanRouteServiceProtocol {
    private let directionsService: DirectionsServiceProtocol

    init(directionsService: DirectionsServiceProtocol = DirectionsService()) {
        self.directionsService = directionsService
    }

    func calculateRoutes(for spots: [PlanSpot]) async throws -> [SpotRoute] {
        guard spots.count >= 2 else {
            AppLogger.directions.info("スポットが2件未満のためルート計算をスキップ")
            return []
        }

        AppLogger.directions.info("ルート計算を開始: \(spots.count)件のスポット")

        var spotRoutes: [SpotRoute] = []

        try await withThrowingTaskGroup(of: SpotRoute?.self) { group in
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
                            return SpotRoute(fromSpotIndex: fromIndex, toSpotIndex: toIndex, route: route)
                        }
                        return nil
                    } catch {
                        AppLogger.directions.warning("ルート計算に失敗 (\(fromSpot.name) → \(toSpot.name)): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            for try await spotRoute in group {
                if let spotRoute = spotRoute {
                    spotRoutes.append(spotRoute)
                }
            }
        }

        spotRoutes.sort { $0.fromSpotIndex < $1.fromSpotIndex }

        AppLogger.directions.info("ルート計算完了: \(spotRoutes.count)件のルートを計算")
        return spotRoutes
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
