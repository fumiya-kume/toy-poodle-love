import Foundation

/// 検索範囲の半径を表す列挙型。
///
/// プラン生成時に、中心座標からどの程度の範囲でスポットを検索するかを指定します。
///
/// ## 使用例
///
/// ```swift
/// let radius = SearchRadius.large
/// print("検索範囲: \(radius.label)")  // "10km"
/// print("メートル: \(radius.meters)") // 10000.0
/// ```
enum SearchRadius: Int, Codable, CaseIterable, Identifiable {
    /// 小範囲（3km）。徒歩圏内のスポットを重視する場合に適しています。
    case small = 3000
    /// 中範囲（5km）。車での短距離移動を想定した標準的な範囲です。
    case medium = 5000
    /// 大範囲（10km）。広域の観光を計画する場合に適しています。デフォルト値です。
    case large = 10000

    var id: Int { rawValue }

    /// 表示用のラベル（例: "10km"）。
    var label: String {
        switch self {
        case .small: return "3km"
        case .medium: return "5km"
        case .large: return "10km"
        }
    }

    /// メートル単位での半径値。
    var meters: Double {
        Double(rawValue)
    }
}
