import Foundation

/// ルート最適化リクエスト
struct RouteOptimizeRequest: Codable, Sendable {
    let origin: RouteWaypoint
    let destination: RouteWaypoint
    let intermediates: [RouteWaypoint]
    let travelMode: TravelMode
    let optimizeWaypointOrder: Bool

    init(
        origin: RouteWaypoint,
        destination: RouteWaypoint,
        intermediates: [RouteWaypoint] = [],
        travelMode: TravelMode = .driving,
        optimizeWaypointOrder: Bool = true
    ) {
        self.origin = origin
        self.destination = destination
        self.intermediates = intermediates
        self.travelMode = travelMode
        self.optimizeWaypointOrder = optimizeWaypointOrder
    }
}
