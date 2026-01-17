import Testing
@testable import handheld

struct AutoDriveConfigurationTests {
    // MARK: - Default Values

    @Test func defaultValues_areCorrect() {
        let config = AutoDriveConfiguration()
        #expect(config.speed == .normal)
        #expect(config.state == .idle)
        #expect(config.initialFetchCount == 3)
        #expect(config.prefetchLookahead == 5)
    }

    // MARK: - isPlaying

    @Test func isPlaying_whenStatePlaying_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .playing
        #expect(config.isPlaying == true)
    }

    @Test func isPlaying_whenStateIdle_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .idle
        #expect(config.isPlaying == false)
    }

    @Test func isPlaying_whenStatePaused_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .paused
        #expect(config.isPlaying == false)
    }

    @Test func isPlaying_whenStateLoading_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .loading(progress: 0.5, fetched: 5, total: 10)
        #expect(config.isPlaying == false)
    }

    @Test func isPlaying_whenStateCompleted_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .completed
        #expect(config.isPlaying == false)
    }

    @Test func isPlaying_whenStateFailed_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .failed(message: "Error")
        #expect(config.isPlaying == false)
    }

    // MARK: - isInitializing

    @Test func isInitializing_whenStateInitializing_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .initializing(fetchedCount: 2, requiredCount: 3)
        #expect(config.isInitializing == true)
    }

    @Test func isInitializing_whenStateIdle_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .idle
        #expect(config.isInitializing == false)
    }

    @Test func isInitializing_whenStatePlaying_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .playing
        #expect(config.isInitializing == false)
    }

    // MARK: - isBuffering

    @Test func isBuffering_whenStateBuffering_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .buffering
        #expect(config.isBuffering == true)
    }

    @Test func isBuffering_whenStatePlaying_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .playing
        #expect(config.isBuffering == false)
    }

    // MARK: - isActive

    @Test func isActive_whenStateIdle_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .idle
        #expect(config.isActive == false)
    }

    @Test func isActive_whenStateCompleted_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .completed
        #expect(config.isActive == false)
    }

    @Test func isActive_whenStateFailed_returnsFalse() {
        var config = AutoDriveConfiguration()
        config.state = .failed(message: "Error")
        #expect(config.isActive == false)
    }

    @Test func isActive_whenStateLoading_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .loading(progress: 0.5, fetched: 5, total: 10)
        #expect(config.isActive == true)
    }

    @Test func isActive_whenStatePlaying_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .playing
        #expect(config.isActive == true)
    }

    @Test func isActive_whenStatePaused_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .paused
        #expect(config.isActive == true)
    }

    @Test func isActive_whenStateInitializing_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .initializing(fetchedCount: 1, requiredCount: 3)
        #expect(config.isActive == true)
    }

    @Test func isActive_whenStateBuffering_returnsTrue() {
        var config = AutoDriveConfiguration()
        config.state = .buffering
        #expect(config.isActive == true)
    }
}
