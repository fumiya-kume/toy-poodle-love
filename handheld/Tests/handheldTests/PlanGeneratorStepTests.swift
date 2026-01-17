import Testing
@testable import handheld

struct PlanGeneratorStepTests {
    // MARK: - rawValue

    @Test func location_rawValue_is0() {
        #expect(PlanGeneratorStep.location.rawValue == 0)
    }

    @Test func category_rawValue_is1() {
        #expect(PlanGeneratorStep.category.rawValue == 1)
    }

    @Test func theme_rawValue_is2() {
        #expect(PlanGeneratorStep.theme.rawValue == 2)
    }

    @Test func confirm_rawValue_is3() {
        #expect(PlanGeneratorStep.confirm.rawValue == 3)
    }

    // MARK: - title

    @Test func location_title_isCorrect() {
        #expect(PlanGeneratorStep.location.title == "エリア選択")
    }

    @Test func category_title_isCorrect() {
        #expect(PlanGeneratorStep.category.title == "カテゴリ選択")
    }

    @Test func theme_title_isCorrect() {
        #expect(PlanGeneratorStep.theme.title == "テーマ設定")
    }

    @Test func confirm_title_isCorrect() {
        #expect(PlanGeneratorStep.confirm.title == "確認")
    }

    // MARK: - isFirst

    @Test func location_isFirst_returnsTrue() {
        #expect(PlanGeneratorStep.location.isFirst == true)
    }

    @Test func category_isFirst_returnsFalse() {
        #expect(PlanGeneratorStep.category.isFirst == false)
    }

    @Test func theme_isFirst_returnsFalse() {
        #expect(PlanGeneratorStep.theme.isFirst == false)
    }

    @Test func confirm_isFirst_returnsFalse() {
        #expect(PlanGeneratorStep.confirm.isFirst == false)
    }

    // MARK: - isLast

    @Test func location_isLast_returnsFalse() {
        #expect(PlanGeneratorStep.location.isLast == false)
    }

    @Test func category_isLast_returnsFalse() {
        #expect(PlanGeneratorStep.category.isLast == false)
    }

    @Test func theme_isLast_returnsFalse() {
        #expect(PlanGeneratorStep.theme.isLast == false)
    }

    @Test func confirm_isLast_returnsTrue() {
        #expect(PlanGeneratorStep.confirm.isLast == true)
    }

    // MARK: - CaseIterable

    @Test func allCases_containsFourCases() {
        #expect(PlanGeneratorStep.allCases.count == 4)
    }

    @Test func allCases_isInCorrectOrder() {
        let cases = PlanGeneratorStep.allCases
        #expect(cases[0] == .location)
        #expect(cases[1] == .category)
        #expect(cases[2] == .theme)
        #expect(cases[3] == .confirm)
    }
}
