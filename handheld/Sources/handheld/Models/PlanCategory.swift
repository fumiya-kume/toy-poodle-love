import SwiftUI

/// 観光プランのカテゴリを表す列挙型。
///
/// ユーザーがプランを作成する際に選択できるカテゴリです。
/// 各カテゴリには、アイコン、色、テーマ提案、検索キーワードが関連付けられています。
///
/// ## 使用例
///
/// ```swift
/// let categories: [PlanCategory] = [.scenic, .activity]
///
/// for category in categories {
///     print("\(category.rawValue): \(category.suggestions)")
/// }
/// ```
enum PlanCategory: String, Codable, CaseIterable, Identifiable {
    /// 景勝地・名所カテゴリ。神社仏閣、城、庭園、公園などの観光名所を検索します。
    case scenic = "景勝地・名所"
    /// 体験・アクティビティカテゴリ。美術館、博物館、レジャー施設などの体験型スポットを検索します。
    case activity = "体験・アクティビティ"
    /// ショッピングカテゴリ。商店街、モール、デパートなどの買い物スポットを検索します。
    case shopping = "ショッピング"

    var id: String { rawValue }

    /// カテゴリを表すSF Symbolsアイコン名。
    var icon: String {
        switch self {
        case .scenic: return "mountain.2.fill"
        case .activity: return "figure.hiking"
        case .shopping: return "bag.fill"
        }
    }

    /// カテゴリを表す色。
    var color: Color {
        switch self {
        case .scenic: return .green
        case .activity: return .orange
        case .shopping: return .blue
        }
    }

    /// テーマ入力時のサジェスト候補。
    var suggestions: [String] {
        switch self {
        case .scenic:
            return ["歴史巡り", "神社仏閣巡り", "自然散策", "絶景スポット巡り", "城めぐり"]
        case .activity:
            return ["美術館巡り", "博物館巡り", "アウトドア体験", "ワークショップ体験", "温泉巡り"]
        case .shopping:
            return ["商店街散策", "アウトレット巡り", "地元グルメ巡り", "お土産探し", "アンティーク巡り"]
        }
    }

    /// MapKit検索に使用するキーワード。
    var searchKeywords: [String] {
        switch self {
        case .scenic:
            return ["観光", "名所", "神社", "寺", "城", "庭園", "公園", "景勝地"]
        case .activity:
            return ["体験", "アクティビティ", "美術館", "博物館", "レジャー"]
        case .shopping:
            return ["ショッピング", "買い物", "モール", "商店街", "デパート"]
        }
    }
}
