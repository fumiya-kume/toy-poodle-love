import Foundation
import SwiftData
import MapKit

/// ユーザーがお気に入りに登録したスポットを表すSwiftDataモデル。
///
/// `FavoriteSpot`は、ユーザーが保存したお気に入りスポットの情報を管理します。
/// ``PlanSpot``から作成することもできます。
///
/// ## 使用例
///
/// ```swift
/// // 直接作成
/// let favorite = FavoriteSpot(
///     name: "金閣寺",
///     address: "京都府京都市北区金閣寺町1",
///     coordinate: CLLocationCoordinate2D(latitude: 35.0394, longitude: 135.7292)
/// )
///
/// // PlanSpotから作成
/// let favorite = FavoriteSpot(from: planSpot)
/// ```
///
/// - SeeAlso: ``PlanSpot``
@Model
final class FavoriteSpot {
    /// スポットの一意識別子。
    var id: UUID
    /// スポット名。
    var name: String
    /// スポットの住所。
    var address: String
    /// スポットの緯度。`coordinate`プロパティを使用してください。
    var latitude: Double
    /// スポットの経度。`coordinate`プロパティを使用してください。
    var longitude: Double
    /// お気に入り追加日時。
    var addedAt: Date

    /// スポットの座標。
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 日本語ロケールの日付フォーマッター（再利用のためキャッシュ）。
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 追加日時のフォーマット済み文字列（日本語ロケール）。
    var formattedAddedAt: String {
        Self.dateFormatter.string(from: addedAt)
    }

    /// お気に入りスポットを作成する。
    ///
    /// - Parameters:
    ///   - name: スポット名
    ///   - address: 住所
    ///   - coordinate: 座標
    init(
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.addedAt = Date()
    }

    /// PlanSpotからお気に入りスポットを作成する。
    ///
    /// - Parameter planSpot: コピー元のプランスポット
    convenience init(from planSpot: PlanSpot) {
        self.init(
            name: planSpot.name,
            address: planSpot.address,
            coordinate: planSpot.coordinate
        )
    }
}
