import Foundation

/// ルート最適化レスポンス
struct RouteOptimizeResponse: Codable {
    let success: Bool
    let optimizedRoute: OptimizedRoute
}

/// Optimized route details
struct OptimizedRoute: Codable {
    let orderedWaypoints: [OptimizedWaypoint]
    let legs: [RouteLeg]
    let totalDistanceMeters: Int
    let totalDurationSeconds: Int
}

/// Optimized waypoint
struct OptimizedWaypoint: Codable, Identifiable {
    let waypoint: RouteWaypoint
    let waypointIndex: Int

    var id: Int { waypointIndex }
}

/// Route leg
struct RouteLeg: Codable {
    let startLocation: LatLng?
    let endLocation: LatLng?
    let distanceMeters: Int
    let durationSeconds: Int
}
