import Foundation

/// シナリオ生成用のルートスポット
struct RouteSpot: Codable, Equatable, Identifiable {
    let name: String
    let type: RouteSpotType
    let description: String?
    let point: String?

    var id: String { name + type.rawValue + (point ?? "") }
}

enum RouteSpotType: String, Codable, CaseIterable, Identifiable {
    case start
    case waypoint
    case destination

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .start:
            return "出発"
        case .waypoint:
            return "経由"
        case .destination:
            return "到着"
        }
    }
}

extension RouteSpotType {
    static func fromGeneratedType(_ value: String) -> RouteSpotType {
        switch value {
        case "start":
            return .start
        case "intermediate":
            return .waypoint
        case "destination":
            return .destination
        default:
            return .waypoint
        }
    }
}
