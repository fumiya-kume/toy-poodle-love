import SwiftUI

enum SuggestionCategory: String, CaseIterable {
    case station       // 駅
    case searchQuery   // 近くを検索
    case poi           // POI/場所
    case hotel         // ホテル
    case restaurant    // 飲食店
    case hospital      // 病院
    case park          // 公園
    case shopping      // 買い物
    case generic       // その他

    var icon: String {
        switch self {
        case .station:
            return "tram.fill"
        case .searchQuery:
            return "magnifyingglass"
        case .poi:
            return "mappin"
        case .hotel:
            return "bed.double.fill"
        case .restaurant:
            return "fork.knife"
        case .hospital:
            return "cross.fill"
        case .park:
            return "leaf.fill"
        case .shopping:
            return "bag.fill"
        case .generic:
            return "mappin"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .station:
            return .green
        case .searchQuery:
            return Color(.systemGray)
        case .poi:
            return .orange
        case .hotel:
            return .purple
        case .restaurant:
            return .orange
        case .hospital:
            return .red
        case .park:
            return .green
        case .shopping:
            return .blue
        case .generic:
            return Color(.systemGray)
        }
    }
}
