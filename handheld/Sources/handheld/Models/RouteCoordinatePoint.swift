import Foundation
import CoreLocation
import MapKit

struct RouteCoordinatePoint: Identifiable {
    let id: UUID
    let index: Int
    let coordinate: CLLocationCoordinate2D
    var lookAroundScene: MKLookAroundScene?
    var isLookAroundLoading: Bool
    var lookAroundFetchFailed: Bool

    init(index: Int, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.index = index
        self.coordinate = coordinate
        self.lookAroundScene = nil
        self.isLookAroundLoading = true
        self.lookAroundFetchFailed = false
    }

    var hasScene: Bool {
        lookAroundScene != nil
    }

    mutating func setLookAroundFetchResult(_ scene: MKLookAroundScene?) {
        lookAroundScene = scene
        isLookAroundLoading = false
        lookAroundFetchFailed = scene == nil
    }
}
