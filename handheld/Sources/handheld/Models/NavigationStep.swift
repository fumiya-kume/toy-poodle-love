import Foundation
import CoreLocation
import MapKit

struct NavigationStep: Identifiable {
    let id: UUID
    let stepIndex: Int
    let coordinate: CLLocationCoordinate2D
    let instructions: String
    let distance: CLLocationDistance
    var lookAroundScene: MKLookAroundScene?
    var isLookAroundLoading: Bool = false
    var lookAroundFetchFailed: Bool = false

    init(step: MKRoute.Step, index: Int) {
        self.id = UUID()
        self.stepIndex = index
        self.coordinate = step.polyline.coordinate
        self.instructions = step.instructions
        self.distance = step.distance
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}
