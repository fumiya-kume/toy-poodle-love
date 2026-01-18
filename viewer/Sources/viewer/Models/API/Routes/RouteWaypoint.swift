import Foundation

/// ルート最適化用のウェイポイント
struct RouteWaypoint: Codable, Equatable, Identifiable {
    let name: String?
    let placeId: String?
    let address: String?
    let location: LatLng?

    private let uuid = UUID().uuidString

    var id: String { placeId ?? address ?? name ?? uuid }

    init(
        name: String? = nil,
        placeId: String? = nil,
        address: String? = nil,
        location: LatLng? = nil
    ) {
        self.name = name
        self.placeId = placeId
        self.address = address
        self.location = location
    }

    enum CodingKeys: String, CodingKey {
        case name
        case placeId
        case address
        case location
    }

    static func == (lhs: RouteWaypoint, rhs: RouteWaypoint) -> Bool {
        lhs.name == rhs.name &&
        lhs.placeId == rhs.placeId &&
        lhs.address == rhs.address &&
        lhs.location == rhs.location
    }
}
