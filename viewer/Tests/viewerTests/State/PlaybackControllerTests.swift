import AVFoundation
import Testing
@testable import VideoOverlayViewer

@MainActor
struct PlaybackControllerTests {
    // MARK: - Initial State Tests

    @Test func initialState_isStopped() {
        let controller = PlaybackController()
        #expect(controller.state == .stopped)
    }

    @Test func initialState_isNotPlaying() {
        let controller = PlaybackController()
        #expect(controller.isPlaying == false)
    }

    @Test func initialState_isNotReady() {
        let controller = PlaybackController()
        #expect(controller.isReady == false)
    }

    @Test func initialState_mainIsNotPlaying() {
        let controller = PlaybackController()
        #expect(controller.isMainPlaying == false)
    }

    @Test func initialState_overlayIsNotPlaying() {
        let controller = PlaybackController()
        #expect(controller.isOverlayPlaying == false)
    }

    // MARK: - Audio Settings Tests

    @Test func isMuted_defaultsFalse() {
        let controller = PlaybackController()
        #expect(controller.isMuted == false)
    }

    @Test func volume_defaultsToOne() {
        let controller = PlaybackController()
        #expect(controller.volume == 1.0)
    }

    @Test func isMuted_canBeSet() {
        let controller = PlaybackController()
        controller.isMuted = true
        #expect(controller.isMuted == true)
    }

    @Test func volume_canBeSet() {
        let controller = PlaybackController()
        controller.volume = 0.5
        #expect(controller.volume == 0.5)
    }

    @Test func volume_canBeSetToZero() {
        let controller = PlaybackController()
        controller.volume = 0.0
        #expect(controller.volume == 0.0)
    }

    // MARK: - Time Tests

    @Test func currentTime_initiallyZero() {
        let controller = PlaybackController()
        #expect(controller.currentTime == .zero)
    }

    @Test func duration_initiallyZero() {
        let controller = PlaybackController()
        #expect(controller.duration == .zero)
    }
}

struct VideoPlaybackStateTests {
    // MARK: - Initial State Tests

    @Test func initialState_hasZeroCurrentTime() {
        let state = VideoPlaybackState()
        #expect(state.currentTime == .zero)
    }

    @Test func initialState_hasZeroDuration() {
        let state = VideoPlaybackState()
        #expect(state.duration == .zero)
    }

    @Test func initialState_isNotPlaying() {
        let state = VideoPlaybackState()
        #expect(state.isPlaying == false)
    }

    // MARK: - Progress Calculation Tests

    @Test func progress_withZeroDuration_returnsZero() {
        let state = VideoPlaybackState()
        #expect(state.progress == 0)
    }

    @Test func progress_atBeginning_returnsZero() {
        var state = VideoPlaybackState()
        state.currentTime = .zero
        state.duration = CMTime(seconds: 60, preferredTimescale: 600)
        #expect(state.progress == 0)
    }

    @Test func progress_atMiddle_returnsHalf() {
        var state = VideoPlaybackState()
        state.currentTime = CMTime(seconds: 30, preferredTimescale: 600)
        state.duration = CMTime(seconds: 60, preferredTimescale: 600)
        #expect(state.progress == 0.5)
    }

    @Test func progress_atEnd_returnsOne() {
        var state = VideoPlaybackState()
        state.currentTime = CMTime(seconds: 60, preferredTimescale: 600)
        state.duration = CMTime(seconds: 60, preferredTimescale: 600)
        #expect(state.progress == 1.0)
    }

    @Test func progress_atQuarter_returnsCorrectValue() {
        var state = VideoPlaybackState()
        state.currentTime = CMTime(seconds: 15, preferredTimescale: 600)
        state.duration = CMTime(seconds: 60, preferredTimescale: 600)
        #expect(state.progress == 0.25)
    }

    @Test func progress_withLongVideo_calculatesCorrectly() {
        var state = VideoPlaybackState()
        state.currentTime = CMTime(seconds: 3600, preferredTimescale: 600) // 1 hour
        state.duration = CMTime(seconds: 7200, preferredTimescale: 600) // 2 hours
        #expect(state.progress == 0.5)
    }
}
