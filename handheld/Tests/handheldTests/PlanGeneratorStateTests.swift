import Testing
@testable import handheld

struct PlanGeneratorStateTests {
    // MARK: - progressMessage

    @Test func idle_progressMessage_isEmpty() {
        #expect(PlanGeneratorState.idle.progressMessage == "")
    }

    @Test func searchingSpots_progressMessage_isCorrect() {
        #expect(PlanGeneratorState.searchingSpots.progressMessage == "スポット検索中...")
    }

    @Test func generatingPlan_progressMessage_isCorrect() {
        #expect(PlanGeneratorState.generatingPlan.progressMessage == "AI生成中...")
    }

    @Test func calculatingRoutes_progressMessage_isCorrect() {
        #expect(PlanGeneratorState.calculatingRoutes.progressMessage == "ルート計算中...")
    }

    @Test func completed_progressMessage_isCorrect() {
        #expect(PlanGeneratorState.completed.progressMessage == "完了")
    }

    @Test func error_progressMessage_returnsErrorMessage() {
        let state = PlanGeneratorState.error(message: "テストエラー")
        #expect(state.progressMessage == "テストエラー")
    }

    // MARK: - progressStep

    @Test func idle_progressStep_is0() {
        #expect(PlanGeneratorState.idle.progressStep == 0)
    }

    @Test func searchingSpots_progressStep_is1() {
        #expect(PlanGeneratorState.searchingSpots.progressStep == 1)
    }

    @Test func generatingPlan_progressStep_is2() {
        #expect(PlanGeneratorState.generatingPlan.progressStep == 2)
    }

    @Test func calculatingRoutes_progressStep_is3() {
        #expect(PlanGeneratorState.calculatingRoutes.progressStep == 3)
    }

    @Test func completed_progressStep_is3() {
        #expect(PlanGeneratorState.completed.progressStep == 3)
    }

    @Test func error_progressStep_is0() {
        let state = PlanGeneratorState.error(message: "Error")
        #expect(state.progressStep == 0)
    }

    // MARK: - Equatable

    @Test func idle_equalsIdle() {
        #expect(PlanGeneratorState.idle == PlanGeneratorState.idle)
    }

    @Test func searchingSpots_equalsSearchingSpots() {
        #expect(PlanGeneratorState.searchingSpots == PlanGeneratorState.searchingSpots)
    }

    @Test func error_equalsErrorWithSameMessage() {
        let state1 = PlanGeneratorState.error(message: "Error")
        let state2 = PlanGeneratorState.error(message: "Error")
        #expect(state1 == state2)
    }

    @Test func error_notEqualsErrorWithDifferentMessage() {
        let state1 = PlanGeneratorState.error(message: "Error1")
        let state2 = PlanGeneratorState.error(message: "Error2")
        #expect(state1 != state2)
    }

    @Test func differentStates_notEqual() {
        #expect(PlanGeneratorState.idle != PlanGeneratorState.searchingSpots)
        #expect(PlanGeneratorState.searchingSpots != PlanGeneratorState.generatingPlan)
        #expect(PlanGeneratorState.generatingPlan != PlanGeneratorState.completed)
    }
}
