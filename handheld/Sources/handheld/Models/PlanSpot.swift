import Foundation
import SwiftData
import MapKit

@Model
final class PlanSpot {
    var id: UUID
    var order: Int
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var aiDescription: String
    var estimatedStayDuration: TimeInterval
    var routeDistanceFromPrevious: Double?
    var routeTravelTimeFromPrevious: TimeInterval?
    var isFavorite: Bool

    var plan: SightseeingPlan?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedStayDuration: String {
        let minutes = Int(estimatedStayDuration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)時間\(remainingMinutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(minutes)分"
        }
    }

    var formattedTravelTimeFromPrevious: String? {
        guard let travelTime = routeTravelTimeFromPrevious else { return nil }
        let minutes = Int(travelTime / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)時間\(remainingMinutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(minutes)分"
        }
    }

    var formattedDistanceFromPrevious: String? {
        guard let distance = routeDistanceFromPrevious else { return nil }
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }

    init(
        order: Int,
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D,
        aiDescription: String,
        estimatedStayDuration: TimeInterval,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.order = order
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.aiDescription = aiDescription
        self.estimatedStayDuration = estimatedStayDuration
        self.isFavorite = isFavorite
    }
}
