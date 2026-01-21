import Foundation
import Testing
@testable import VideoOverlayViewer

struct PlaybackStateTests {
    // MARK: - Equality Tests

    @Test func stopped_equalsStopped() {
        #expect(PlaybackState.stopped == PlaybackState.stopped)
    }

    @Test func ready_equalsReady() {
        #expect(PlaybackState.ready == PlaybackState.ready)
    }

    @Test func playing_equalsPlaying() {
        #expect(PlaybackState.playing == PlaybackState.playing)
    }

    @Test func paused_equalsPaused() {
        #expect(PlaybackState.paused == PlaybackState.paused)
    }

    @Test func error_equalsErrorWithSameMessage() {
        #expect(PlaybackState.error("test error") == PlaybackState.error("test error"))
    }

    @Test func error_notEqualsErrorWithDifferentMessage() {
        #expect(PlaybackState.error("error 1") != PlaybackState.error("error 2"))
    }

    // MARK: - Inequality Tests

    @Test func stopped_notEqualsPlaying() {
        #expect(PlaybackState.stopped != PlaybackState.playing)
    }

    @Test func stopped_notEqualsReady() {
        #expect(PlaybackState.stopped != PlaybackState.ready)
    }

    @Test func stopped_notEqualsPaused() {
        #expect(PlaybackState.stopped != PlaybackState.paused)
    }

    @Test func stopped_notEqualsError() {
        #expect(PlaybackState.stopped != PlaybackState.error("some error"))
    }

    @Test func ready_notEqualsPlaying() {
        #expect(PlaybackState.ready != PlaybackState.playing)
    }

    @Test func ready_notEqualsPaused() {
        #expect(PlaybackState.ready != PlaybackState.paused)
    }

    @Test func playing_notEqualsPaused() {
        #expect(PlaybackState.playing != PlaybackState.paused)
    }

    @Test func playing_notEqualsError() {
        #expect(PlaybackState.playing != PlaybackState.error("some error"))
    }

    // MARK: - Error Message Tests

    @Test func error_withEmptyMessage_equalsOtherEmptyError() {
        #expect(PlaybackState.error("") == PlaybackState.error(""))
    }

    @Test func error_withJapaneseMessage_equalsCorrectly() {
        #expect(PlaybackState.error("エラーが発生しました") == PlaybackState.error("エラーが発生しました"))
    }

    @Test func error_withLongMessage_equalsCorrectly() {
        let longMessage = String(repeating: "error ", count: 100)
        #expect(PlaybackState.error(longMessage) == PlaybackState.error(longMessage))
    }
}
