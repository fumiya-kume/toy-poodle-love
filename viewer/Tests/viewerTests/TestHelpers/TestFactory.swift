import Foundation
import CoreLocation
@testable import VideoOverlayViewer

enum TestFactory {
    // MARK: - VideoConfiguration

    static func createVideoConfiguration(
        id: UUID = UUID(),
        windowIndex: Int = 0,
        mainVideoBookmark: Data? = nil,
        overlayVideoBookmark: Data? = nil,
        overlayOpacity: Double = 1.0
    ) -> VideoConfiguration {
        VideoConfiguration(
            id: id,
            windowIndex: windowIndex,
            mainVideoBookmark: mainVideoBookmark,
            overlayVideoBookmark: overlayVideoBookmark,
            overlayOpacity: overlayOpacity
        )
    }

    // MARK: - MapSpot

    static func createMapSpot(
        id: UUID = UUID(),
        name: String = "テストスポット",
        latitude: Double = 35.6812,
        longitude: Double = 139.7671,
        type: MapSpot.MapSpotType = .waypoint,
        address: String? = "東京都千代田区",
        description: String? = nil,
        order: Int = 1
    ) -> MapSpot {
        MapSpot(
            id: id,
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            type: type,
            address: address,
            description: description,
            order: order
        )
    }

    // MARK: - LatLng

    static func createLatLng(
        latitude: Double = 35.6812,
        longitude: Double = 139.7671
    ) -> LatLng {
        LatLng(latitude: latitude, longitude: longitude)
    }

    // MARK: - RouteSpot

    static func createRouteSpot(
        name: String = "テストスポット",
        type: RouteSpotType = .waypoint,
        description: String? = nil,
        point: String? = nil
    ) -> RouteSpot {
        RouteSpot(
            name: name,
            type: type,
            description: description,
            point: point
        )
    }

    // MARK: - Coordinate

    static func createCoordinate(
        latitude: Double = 35.6812,
        longitude: Double = 139.7671
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
