import Testing
@testable import handheld

struct AutoDriveStateTests {
    // MARK: - Equatable

    @Test func idle_equalsIdle() {
        #expect(AutoDriveState.idle == AutoDriveState.idle)
    }

    @Test func playing_equalsPlaying() {
        #expect(AutoDriveState.playing == AutoDriveState.playing)
    }

    @Test func paused_equalsPaused() {
        #expect(AutoDriveState.paused == AutoDriveState.paused)
    }

    @Test func completed_equalsCompleted() {
        #expect(AutoDriveState.completed == AutoDriveState.completed)
    }

    @Test func buffering_equalsBuffering() {
        #expect(AutoDriveState.buffering == AutoDriveState.buffering)
    }

    @Test func loading_equalsLoadingWithSameValues() {
        let state1 = AutoDriveState.loading(progress: 0.5, fetched: 5, total: 10)
        let state2 = AutoDriveState.loading(progress: 0.5, fetched: 5, total: 10)
        #expect(state1 == state2)
    }

    @Test func loading_notEqualsLoadingWithDifferentValues() {
        let state1 = AutoDriveState.loading(progress: 0.5, fetched: 5, total: 10)
        let state2 = AutoDriveState.loading(progress: 0.6, fetched: 6, total: 10)
        #expect(state1 != state2)
    }

    @Test func initializing_equalsInitializingWithSameValues() {
        let state1 = AutoDriveState.initializing(fetchedCount: 2, requiredCount: 3)
        let state2 = AutoDriveState.initializing(fetchedCount: 2, requiredCount: 3)
        #expect(state1 == state2)
    }

    @Test func initializing_notEqualsInitializingWithDifferentValues() {
        let state1 = AutoDriveState.initializing(fetchedCount: 2, requiredCount: 3)
        let state2 = AutoDriveState.initializing(fetchedCount: 1, requiredCount: 3)
        #expect(state1 != state2)
    }

    @Test func failed_equalsFailedWithSameMessage() {
        let state1 = AutoDriveState.failed(message: "Error")
        let state2 = AutoDriveState.failed(message: "Error")
        #expect(state1 == state2)
    }

    @Test func failed_notEqualsFailedWithDifferentMessage() {
        let state1 = AutoDriveState.failed(message: "Error1")
        let state2 = AutoDriveState.failed(message: "Error2")
        #expect(state1 != state2)
    }

    @Test func differentStates_notEqual() {
        #expect(AutoDriveState.idle != AutoDriveState.playing)
        #expect(AutoDriveState.playing != AutoDriveState.paused)
        #expect(AutoDriveState.paused != AutoDriveState.completed)
        #expect(AutoDriveState.buffering != AutoDriveState.playing)
    }
}
