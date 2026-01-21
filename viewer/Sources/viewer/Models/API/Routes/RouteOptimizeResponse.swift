import Foundation

/// ルート最適化レスポンス
struct RouteOptimizeResponse: Codable, Sendable {
    let success: Bool
    let optimizedRoute: OptimizedRoute
}

/// Optimized route details
struct OptimizedRoute: Codable, Sendable {
    let orderedWaypoints: [OptimizedWaypoint]
    let legs: [RouteLeg]
    let totalDistanceMeters: Int
    let totalDurationSeconds: Int
}

/// Optimized waypoint
struct OptimizedWaypoint: Codable, Identifiable, Sendable {
    let waypoint: RouteWaypoint
    let waypointIndex: Int

    var id: Int { waypointIndex }
}

/// Route leg
struct RouteLeg: Codable, Sendable {
    let startLocation: LatLng?
    let endLocation: LatLng?
    let distanceMeters: Int
    let durationSeconds: Int
}
