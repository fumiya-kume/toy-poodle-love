import Foundation

/// ジオコーディングリクエスト
struct GeocodeRequest: Codable, Sendable {
    let addresses: [String]
}
