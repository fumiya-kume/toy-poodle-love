import Foundation
import MapKit

struct Place: Identifiable, Equatable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem

    init(mapItem: MKMapItem) {
        self.id = UUID()
        self.name = mapItem.name ?? "不明な場所"
        self.address = mapItem.placemark.title ?? ""
        self.coordinate = mapItem.placemark.coordinate
        self.mapItem = mapItem
    }

    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
}
