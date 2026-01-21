import CoreLocation
import Foundation
import MapKit
@testable import handheld

// MARK: - Mock Route for Testing

/// テスト用のモックRoute
/// 注: 実際のMKRouteはイニシャライザがないため、独自のモックを使用
struct MockRoute {
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval

    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

    var formattedTravelTime: String {
        let hours = Int(expectedTravelTime) / 3600
        let minutes = Int(expectedTravelTime) % 3600 / 60

        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

enum TestFactory {
    static func createMockPlace(
        name: String = "テスト場所",
        address: String = "東京都千代田区",
        latitude: Double = 35.6812,
        longitude: Double = 139.7671
    ) -> Place {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return Place(mapItem: mapItem)
    }

    static func createMockPlanSpot(
        order: Int = 0,
        name: String = "テストスポット",
        address: String = "東京都千代田区",
        latitude: Double = 35.6812,
        longitude: Double = 139.7671,
        aiDescription: String = "テスト説明",
        stayDuration: TimeInterval = 30 * 60,
        routeDistanceFromPrevious: Double? = nil,
        routeTravelTimeFromPrevious: TimeInterval? = nil,
        isFavorite: Bool = false
    ) -> PlanSpot {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let spot = PlanSpot(
            order: order,
            name: name,
            address: address,
            coordinate: coordinate,
            aiDescription: aiDescription,
            estimatedStayDuration: stayDuration,
            isFavorite: isFavorite
        )
        spot.routeDistanceFromPrevious = routeDistanceFromPrevious
        spot.routeTravelTimeFromPrevious = routeTravelTimeFromPrevious
        return spot
    }

    static func createMockCoordinate(
        latitude: Double = 35.6812,
        longitude: Double = 139.7671
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func createMockRoute(
        distance: CLLocationDistance = 1000,
        travelTime: TimeInterval = 30 * 60
    ) -> MockRoute {
        MockRoute(distance: distance, expectedTravelTime: travelTime)
    }

    static func createMockSpotRoute(
        fromSpotIndex: Int = 0,
        toSpotIndex: Int = 1,
        distance: CLLocationDistance = 1000,
        travelTime: TimeInterval = 30 * 60
    ) -> MockSpotRoute {
        MockSpotRoute(
            fromSpotIndex: fromSpotIndex,
            toSpotIndex: toSpotIndex,
            distance: distance,
            expectedTravelTime: travelTime
        )
    }

    static func createGeneratedSpotInfo(
        name: String = "テストスポット",
        description: String = "テスト説明",
        stayMinutes: Int = 30
    ) -> GeneratedSpotInfo {
        GeneratedSpotInfo(name: name, description: description, stayMinutes: stayMinutes)
    }
}

// MARK: - Mock SpotRoute for Testing

/// テスト用のモックSpotRoute
struct MockSpotRoute {
    let fromSpotIndex: Int
    let toSpotIndex: Int
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
}
