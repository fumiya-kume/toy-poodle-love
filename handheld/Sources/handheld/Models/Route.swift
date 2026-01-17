import Foundation
import MapKit

struct Route: Identifiable {
    let id: UUID
    let polyline: MKPolyline
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let steps: [MKRoute.Step]

    init(mkRoute: MKRoute) {
        self.id = UUID()
        self.polyline = mkRoute.polyline
        self.distance = mkRoute.distance
        self.expectedTravelTime = mkRoute.expectedTravelTime
        self.steps = mkRoute.steps
    }

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
