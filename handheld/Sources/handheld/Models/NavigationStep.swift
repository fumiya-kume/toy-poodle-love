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
    var isLookAroundLoading: Bool = true
    var lookAroundFetchFailed: Bool = false

    init(step: MKRoute.Step, index: Int) {
        self.id = UUID()
        self.stepIndex = index
        self.coordinate = step.polyline.coordinate
        self.instructions = step.instructions
        self.distance = step.distance
    }

    var displayInstructions: String {
        instructions.isEmpty ? "直進" : instructions
    }

    mutating func setLookAroundFetchResult(_ scene: MKLookAroundScene?) {
        lookAroundScene = scene
        isLookAroundLoading = false
        lookAroundFetchFailed = scene == nil
    }
}
