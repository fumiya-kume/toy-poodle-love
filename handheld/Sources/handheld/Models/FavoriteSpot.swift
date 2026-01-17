import Foundation
import SwiftData
import MapKit

@Model
final class FavoriteSpot {
    var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var addedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedAddedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: addedAt)
    }

    init(
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.addedAt = Date()
    }

    convenience init(from planSpot: PlanSpot) {
        self.init(
            name: planSpot.name,
            address: planSpot.address,
            coordinate: planSpot.coordinate
        )
    }
}
