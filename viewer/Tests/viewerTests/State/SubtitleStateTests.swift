import Foundation
import Testing
@testable import VideoOverlayViewer

@MainActor
struct SubtitleStateTests {
    // MARK: - Initial State Tests

    @Test func initialState_hasNilText() {
        let state = SubtitleState()
        #expect(state.currentText == nil)
    }

    // MARK: - Show Tests

    @Test func show_setsCurrentText() {
        let state = SubtitleState()
        state.show("テスト字幕")
        #expect(state.currentText == "テスト字幕")
    }

    @Test func show_withEmptyString_setsEmptyText() {
        let state = SubtitleState()
        state.show("")
        #expect(state.currentText == "")
    }

    @Test func show_withMultilineText_setsCorrectly() {
        let state = SubtitleState()
        let multilineText = "一行目\n二行目\n三行目"
        state.show(multilineText)
        #expect(state.currentText == multilineText)
    }

    @Test func show_withLongText_setsCorrectly() {
        let state = SubtitleState()
        let longText = String(repeating: "テスト", count: 100)
        state.show(longText)
        #expect(state.currentText == longText)
    }

    @Test func show_calledMultipleTimes_updatesText() {
        let state = SubtitleState()
        state.show("最初のテキスト")
        state.show("次のテキスト")
        #expect(state.currentText == "次のテキスト")
    }

    // MARK: - Clear Tests

    @Test func clear_resetsToNil() {
        let state = SubtitleState()
        state.show("テスト字幕")
        state.clear()
        #expect(state.currentText == nil)
    }

    @Test func clear_onAlreadyNilState_remainsNil() {
        let state = SubtitleState()
        state.clear()
        #expect(state.currentText == nil)
    }

    @Test func clear_afterMultipleShows_resetsToNil() {
        let state = SubtitleState()
        state.show("テキスト1")
        state.show("テキスト2")
        state.show("テキスト3")
        state.clear()
        #expect(state.currentText == nil)
    }

    // MARK: - Combined Operations Tests

    @Test func showClearShow_worksCorrectly() {
        let state = SubtitleState()
        state.show("最初")
        state.clear()
        state.show("最後")
        #expect(state.currentText == "最後")
    }

    @Test func multipleClearCalls_noSideEffects() {
        let state = SubtitleState()
        state.show("テスト")
        state.clear()
        state.clear()
        state.clear()
        #expect(state.currentText == nil)
    }
}
