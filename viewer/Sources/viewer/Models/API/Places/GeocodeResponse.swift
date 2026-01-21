import Foundation

/// ジオコーディングレスポンス
struct GeocodeResponse: Codable, Sendable {
    /// 成功フラグ
    let success: Bool
    /// ジオコーディングされた場所の配列
    let places: [GeocodedPlace]
}
