import SwiftUI
import Testing
@testable import handheld

struct PlanCategoryTests {
    // MARK: - icon

    @Test func scenic_icon_isMountain() {
        #expect(PlanCategory.scenic.icon == "mountain.2.fill")
    }

    @Test func activity_icon_isHiking() {
        #expect(PlanCategory.activity.icon == "figure.hiking")
    }

    @Test func shopping_icon_isBag() {
        #expect(PlanCategory.shopping.icon == "bag.fill")
    }

    // MARK: - color

    @Test func scenic_color_isGreen() {
        #expect(PlanCategory.scenic.color == .green)
    }

    @Test func activity_color_isOrange() {
        #expect(PlanCategory.activity.color == .orange)
    }

    @Test func shopping_color_isBlue() {
        #expect(PlanCategory.shopping.color == .blue)
    }

    // MARK: - suggestions

    @Test func scenic_suggestions_hasCorrectCount() {
        #expect(PlanCategory.scenic.suggestions.count == 5)
    }

    @Test func scenic_suggestions_containsExpectedItems() {
        let suggestions = PlanCategory.scenic.suggestions
        #expect(suggestions.contains("歴史巡り"))
        #expect(suggestions.contains("神社仏閣巡り"))
        #expect(suggestions.contains("自然散策"))
    }

    @Test func activity_suggestions_hasCorrectCount() {
        #expect(PlanCategory.activity.suggestions.count == 5)
    }

    @Test func activity_suggestions_containsExpectedItems() {
        let suggestions = PlanCategory.activity.suggestions
        #expect(suggestions.contains("美術館巡り"))
        #expect(suggestions.contains("博物館巡り"))
    }

    @Test func shopping_suggestions_hasCorrectCount() {
        #expect(PlanCategory.shopping.suggestions.count == 5)
    }

    @Test func shopping_suggestions_containsExpectedItems() {
        let suggestions = PlanCategory.shopping.suggestions
        #expect(suggestions.contains("商店街散策"))
        #expect(suggestions.contains("地元グルメ巡り"))
    }

    // MARK: - searchKeywords

    @Test func scenic_searchKeywords_containsExpectedItems() {
        let keywords = PlanCategory.scenic.searchKeywords
        #expect(keywords.contains("観光"))
        #expect(keywords.contains("名所"))
        #expect(keywords.contains("神社"))
    }

    @Test func activity_searchKeywords_containsExpectedItems() {
        let keywords = PlanCategory.activity.searchKeywords
        #expect(keywords.contains("体験"))
        #expect(keywords.contains("美術館"))
    }

    @Test func shopping_searchKeywords_containsExpectedItems() {
        let keywords = PlanCategory.shopping.searchKeywords
        #expect(keywords.contains("ショッピング"))
        #expect(keywords.contains("買い物"))
    }

    // MARK: - rawValue

    @Test func scenic_rawValue_isCorrect() {
        #expect(PlanCategory.scenic.rawValue == "景勝地・名所")
    }

    @Test func activity_rawValue_isCorrect() {
        #expect(PlanCategory.activity.rawValue == "体験・アクティビティ")
    }

    @Test func shopping_rawValue_isCorrect() {
        #expect(PlanCategory.shopping.rawValue == "ショッピング")
    }

    // MARK: - CaseIterable

    @Test func allCases_containsThreeCases() {
        #expect(PlanCategory.allCases.count == 3)
    }

    // MARK: - id

    @Test func id_equalsRawValue() {
        #expect(PlanCategory.scenic.id == PlanCategory.scenic.rawValue)
    }
}
