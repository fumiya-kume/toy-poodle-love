import Foundation

/// ジオコーディングされた場所
struct GeocodedPlace: Codable, Identifiable, Sendable {
    /// 入力された住所
    let inputAddress: String
    /// 座標
    let location: LatLng
    /// フォーマット済みの住所
    let formattedAddress: String
    /// Google Place ID
    let placeId: String

    var id: String { placeId }
}
