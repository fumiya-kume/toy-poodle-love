import Foundation

/// 移動モード
enum TravelMode: String, Codable, CaseIterable, Identifiable {
    case driving = "DRIVE"
    case walking = "WALK"
    case bicycling = "BICYCLE"
    case transit = "TRANSIT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .driving:
            return "車"
        case .walking:
            return "徒歩"
        case .bicycling:
            return "自転車"
        case .transit:
            return "公共交通機関"
        }
    }
}
