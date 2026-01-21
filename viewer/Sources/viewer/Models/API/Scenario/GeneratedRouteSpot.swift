import Foundation

/// AIで生成されたルートスポット
struct GeneratedRouteSpot: Codable, Identifiable, Sendable {
    let name: String
    let type: String
    let description: String?
    let generatedNote: String?

    var id: String { name + type }

    func toRouteSpot() -> RouteSpot {
        RouteSpot(
            name: name,
            type: RouteSpotType.fromGeneratedType(type),
            description: description,
            point: generatedNote
        )
    }
}
