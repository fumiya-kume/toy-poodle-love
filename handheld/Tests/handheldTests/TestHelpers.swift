import CoreLocation
import MapKit
@testable import handheld

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
}
