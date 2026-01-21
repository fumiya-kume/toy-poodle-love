import Foundation

/// 緯度・経度を表す構造体
struct LatLng: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}
