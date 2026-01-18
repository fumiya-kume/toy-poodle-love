import Foundation

/// ジオコーディングレスポンス
struct GeocodeResponse: Codable {
    /// 成功フラグ
    let success: Bool
    /// ジオコーディングされた場所の配列
    let places: [GeocodedPlace]
}
