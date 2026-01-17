import Foundation
import SwiftData
import MapKit

/// 観光プラン内の個別スポットを表すSwiftDataモデル。
///
/// `PlanSpot`は、``SightseeingPlan``に含まれる各訪問地点の情報を管理します。
/// 位置情報、滞在時間、前のスポットからのルート情報などを保持します。
///
/// ## 使用例
///
/// ```swift
/// let spot = PlanSpot(
///     order: 0,
///     name: "金閣寺",
///     address: "京都府京都市北区金閣寺町1",
///     coordinate: CLLocationCoordinate2D(latitude: 35.0394, longitude: 135.7292),
///     aiDescription: "室町時代の名建築",
///     estimatedStayDuration: 3600
/// )
/// ```
///
/// - SeeAlso: ``SightseeingPlan``, ``FavoriteSpot``
@Model
final class PlanSpot {
    /// スポットの一意識別子。
    var id: UUID
    /// 訪問順序（0から開始）。
    var order: Int
    /// スポット名。
    var name: String
    /// スポットの住所。
    var address: String
    /// スポットの緯度。`coordinate`プロパティを使用してください。
    var latitude: Double
    /// スポットの経度。`coordinate`プロパティを使用してください。
    var longitude: Double
    /// AI生成による説明文。
    var aiDescription: String
    /// 推定滞在時間（秒）。
    var estimatedStayDuration: TimeInterval
    /// 前のスポットからの移動距離（メートル）。最初のスポットは`nil`。
    var routeDistanceFromPrevious: Double?
    /// 前のスポットからの移動時間（秒）。最初のスポットは`nil`。
    var routeTravelTimeFromPrevious: TimeInterval?
    /// お気に入りフラグ。
    var isFavorite: Bool

    /// このスポットが属するプラン。
    var plan: SightseeingPlan?

    /// スポットの座標。
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 滞在時間のフォーマット済み文字列（例: "1時間30分"）。
    var formattedStayDuration: String {
        estimatedStayDuration.formattedDuration
    }

    /// 前のスポットからの移動時間のフォーマット済み文字列。移動時間が未設定の場合は`nil`。
    var formattedTravelTimeFromPrevious: String? {
        routeTravelTimeFromPrevious?.formattedDuration
    }

    /// 前のスポットからの移動距離のフォーマット済み文字列。移動距離が未設定の場合は`nil`。
    var formattedDistanceFromPrevious: String? {
        guard let distance = routeDistanceFromPrevious else { return nil }
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }

    /// スポットを作成する。
    ///
    /// - Parameters:
    ///   - order: 訪問順序（0から開始）
    ///   - name: スポット名
    ///   - address: 住所
    ///   - coordinate: 座標
    ///   - aiDescription: AI生成の説明文
    ///   - estimatedStayDuration: 推定滞在時間（秒）
    ///   - isFavorite: お気に入りフラグ（デフォルトは`false`）
    init(
        order: Int,
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D,
        aiDescription: String,
        estimatedStayDuration: TimeInterval,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.order = order
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.aiDescription = aiDescription
        self.estimatedStayDuration = estimatedStayDuration
        self.isFavorite = isFavorite
    }
}
