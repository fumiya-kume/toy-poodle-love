import SwiftUI

enum PlanCategory: String, Codable, CaseIterable, Identifiable {
    case scenic = "景勝地・名所"
    case activity = "体験・アクティビティ"
    case shopping = "ショッピング"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scenic: return "mountain.2.fill"
        case .activity: return "figure.hiking"
        case .shopping: return "bag.fill"
        }
    }

    var color: Color {
        switch self {
        case .scenic: return .green
        case .activity: return .orange
        case .shopping: return .blue
        }
    }

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
