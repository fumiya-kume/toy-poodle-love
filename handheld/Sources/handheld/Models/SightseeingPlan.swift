import Foundation
import SwiftData
import MapKit

/// 観光プランを表すSwiftDataモデル。
///
/// `SightseeingPlan`は、ユーザーが作成した観光プランの全情報を管理します。
/// 複数の``PlanSpot``を含み、それらの訪問順序やルート情報を保持します。
///
/// ## 使用例
///
/// ```swift
/// let plan = SightseeingPlan(
///     title: "京都歴史巡り",
///     theme: "神社仏閣巡り",
///     categories: [.scenic],
///     searchRadius: .large,
///     centerCoordinate: CLLocationCoordinate2D(latitude: 35.0, longitude: 135.7),
///     startTime: Date()
/// )
/// ```
///
/// - SeeAlso: ``PlanSpot``, ``PlanCategory``, ``SearchRadius``
@Model
final class SightseeingPlan {
    /// プランの一意識別子。
    var id: UUID
    /// プランのタイトル。
    var title: String
    /// プランのテーマ（例: "神社仏閣巡り"）。
    var theme: String
    /// カテゴリのraw値（カンマ区切り）。`categories`プロパティを使用してください。
    var categoriesRawValue: String
    /// プラン開始予定時刻。
    var startTime: Date?
    /// プラン作成日時。
    var createdAt: Date
    /// プラン更新日時。
    var updatedAt: Date
    /// プラン全体の合計所要時間（秒）。
    var totalDuration: TimeInterval
    /// プラン全体の合計移動距離（メートル）。
    var totalDistance: Double
    /// 検索半径のraw値。`searchRadius`プロパティを使用してください。
    var searchRadiusRawValue: Int
    /// 検索中心の緯度。`centerCoordinate`プロパティを使用してください。
    var centerLatitude: Double
    /// 検索中心の経度。`centerCoordinate`プロパティを使用してください。
    var centerLongitude: Double

    /// プランに含まれるスポットのリスト。プラン削除時にカスケード削除されます。
    @Relationship(deleteRule: .cascade, inverse: \PlanSpot.plan)
    var spots: [PlanSpot]

    /// 選択されたカテゴリのリスト。
    var categories: [PlanCategory] {
        get {
            categoriesRawValue.split(separator: ",").compactMap { PlanCategory(rawValue: String($0)) }
        }
        set {
            categoriesRawValue = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }

    /// 検索半径。
    var searchRadius: SearchRadius {
        get {
            SearchRadius(rawValue: searchRadiusRawValue) ?? .large
        }
        set {
            searchRadiusRawValue = newValue.rawValue
        }
    }

    /// 検索中心の座標。
    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    /// 訪問順序でソートされたスポットのリスト。
    var sortedSpots: [PlanSpot] {
        spots.sorted { $0.order < $1.order }
    }

    /// 合計所要時間のフォーマット済み文字列（例: "2時間30分"）。
    var formattedTotalDuration: String {
        totalDuration.formattedDuration
    }

    /// 合計移動距離のフォーマット済み文字列（例: "5.2km"）。
    var formattedTotalDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1fkm", totalDistance / 1000)
        } else {
            return "\(Int(totalDistance))m"
        }
    }

    /// 日本語ロケールの日付フォーマッター（再利用のためキャッシュ）。
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 作成日時のフォーマット済み文字列（日本語ロケール）。
    var formattedCreatedAt: String {
        Self.dateFormatter.string(from: createdAt)
    }

    /// 観光プランを作成する。
    ///
    /// - Parameters:
    ///   - title: プランのタイトル
    ///   - theme: プランのテーマ
    ///   - categories: 選択されたカテゴリのリスト
    ///   - searchRadius: 検索半径
    ///   - centerCoordinate: 検索中心の座標
    ///   - startTime: 開始予定時刻（オプション）
    ///   - spots: 初期スポットリスト（デフォルトは空）
    init(
        title: String,
        theme: String,
        categories: [PlanCategory],
        searchRadius: SearchRadius,
        centerCoordinate: CLLocationCoordinate2D,
        startTime: Date? = nil,
        spots: [PlanSpot] = []
    ) {
        self.id = UUID()
        self.title = title
        self.theme = theme
        self.categoriesRawValue = categories.map { $0.rawValue }.joined(separator: ",")
        self.searchRadiusRawValue = searchRadius.rawValue
        self.centerLatitude = centerCoordinate.latitude
        self.centerLongitude = centerCoordinate.longitude
        self.startTime = startTime
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalDuration = 0
        self.totalDistance = 0
        self.spots = spots
    }

    /// 指定したスポットの予定到着時刻を計算する。
    ///
    /// 開始時刻から各スポットの滞在時間と移動時間を累積して計算します。
    ///
    /// - Parameter spot: 計算対象のスポット
    /// - Returns: 予定到着時刻。開始時刻が未設定またはスポットがプランに含まれない場合は`nil`
    func calculateScheduledTime(for spot: PlanSpot) -> Date? {
        guard let startTime = startTime else { return nil }

        let sortedSpots = self.sortedSpots
        guard let index = sortedSpots.firstIndex(where: { $0.id == spot.id }) else { return nil }

        var currentTime = startTime

        for i in 0..<index {
            let previousSpot = sortedSpots[i]
            currentTime = currentTime.addingTimeInterval(previousSpot.estimatedStayDuration)
            if let travelTime = sortedSpots[i + 1].routeTravelTimeFromPrevious {
                currentTime = currentTime.addingTimeInterval(travelTime)
            }
        }

        return currentTime
    }

    /// 指定したスポットの予定到着時刻をフォーマット済み文字列で返す。
    ///
    /// - Parameter spot: 計算対象のスポット
    /// - Returns: "HH:mm"形式の文字列。計算できない場合は`nil`
    func formattedScheduledTime(for spot: PlanSpot) -> String? {
        guard let scheduledTime = calculateScheduledTime(for: spot) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledTime)
    }
}
