import MapKit

struct MapSpot: Identifiable, Equatable, Hashable {
    enum MapSpotType: Hashable {
        case start
        case waypoint
        case destination
    }

    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: MapSpotType
    let address: String?
    let description: String?
    let order: Int

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        type: MapSpotType,
        address: String?,
        description: String?,
        order: Int
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.type = type
        self.address = address
        self.description = description
        self.order = order
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MapSpot, rhs: MapSpot) -> Bool {
        lhs.id == rhs.id
    }
}
