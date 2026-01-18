import Foundation

/// ジオコーディングリクエスト
struct GeocodeRequest: Codable {
    let addresses: [String]
}
