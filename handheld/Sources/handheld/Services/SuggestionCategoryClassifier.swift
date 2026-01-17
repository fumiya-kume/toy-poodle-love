import Foundation
import SwiftUI

struct SuggestionCategoryClassifier {
    // 駅のパターン
    private static let stationPatterns = [
        "駅", "Station", "Sta.", "停留所", "停留場", "ターミナル"
    ]

    // ホテルのパターン
    private static let hotelPatterns = [
        "ホテル", "Hotel", "旅館", "民宿", "ゲストハウス", "GUESTHOUSE",
        "イン", "Inn", "ペンション", "Pension", "宿"
    ]

    // レストラン/飲食のパターン
    private static let restaurantPatterns = [
        "レストラン", "Restaurant", "カフェ", "Cafe", "喫茶",
        "食堂", "居酒屋", "ラーメン", "寿司", "焼肉", "焼き鳥",
        "うどん", "そば", "蕎麦", "定食", "バー", "Bar"
    ]

    // 病院のパターン
    private static let hospitalPatterns = [
        "病院", "Hospital", "クリニック", "Clinic", "医院",
        "診療所", "歯科", "眼科", "内科", "外科", "薬局"
    ]

    // 公園のパターン
    private static let parkPatterns = [
        "公園", "Park", "庭園", "Garden", "緑地", "広場"
    ]

    // 買い物のパターン
    private static let shoppingPatterns = [
        "モール", "Mall", "百貨店", "デパート", "ストア", "Store",
        "マート", "Mart", "ショッピング", "Shopping", "スーパー",
        "コンビニ", "ドラッグストア"
    ]

    private static func isLikelyAddress(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        let addressKeywords = [
            "丁目", "番地", "番", "号",
            "都", "道", "府", "県",
            "市", "区", "町", "村"
        ]

        let containsAddressKeyword = addressKeywords.contains(where: { text.contains($0) })
        let containsDigit = text.rangeOfCharacter(from: .decimalDigits) != nil

        return containsAddressKeyword && containsDigit
    }

    static func classify(title: String, subtitle: String) -> SuggestionCategory {
        let combined = title + subtitle
        let likelyAddressSubtitle = isLikelyAddress(subtitle)
        let textForPatternMatching = likelyAddressSubtitle ? title : combined

        // 駅を最優先でチェック（日本では最も重要なカテゴリ）
        if stationPatterns.contains(where: { textForPatternMatching.localizedCaseInsensitiveContains($0) }) {
            return .station
        }

        // 「近くを検索」系のクエリ型サジェスト
        if subtitle.contains("近くを検索") {
            return .searchQuery
        }

        if hotelPatterns.contains(where: { textForPatternMatching.localizedCaseInsensitiveContains($0) }) {
            return .hotel
        }

        if restaurantPatterns.contains(where: { textForPatternMatching.localizedCaseInsensitiveContains($0) }) {
            return .restaurant
        }

        if hospitalPatterns.contains(where: { textForPatternMatching.localizedCaseInsensitiveContains($0) }) {
            return .hospital
        }

        if parkPatterns.contains(where: { textForPatternMatching.localizedCaseInsensitiveContains($0) }) {
            return .park
        }

        if shoppingPatterns.contains(where: { textForPatternMatching.localizedCaseInsensitiveContains($0) }) {
            return .shopping
        }

        // サブタイトルに住所情報がある場合はPOI
        if likelyAddressSubtitle || !subtitle.isEmpty {
            return .poi
        }

        return .generic
    }
}
