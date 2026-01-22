import AVFoundation
import Testing
@testable import VideoOverlayViewer

@MainActor
struct TTSControllerTests {
    // MARK: - Initial State Tests

    @Test func initialState_isNotSpeaking() {
        let controller = TTSController()
        #expect(controller.isSpeaking == false)
    }

    @Test func initialState_isNotPaused() {
        let controller = TTSController()
        #expect(controller.isPaused == false)
    }

    // MARK: - setSubtitleState Tests

    @Test func setSubtitleState_setsReference() {
        let controller = TTSController()
        let subtitleState = SubtitleState()

        controller.setSubtitleState(subtitleState)

        // 参照が設定されていることを間接的に確認
        // speak()を呼ぶとsubtitleStateが更新される
        controller.speak("テスト")
        #expect(subtitleState.currentText == "テスト")
    }

    // MARK: - speak Tests

    @Test func speak_setsSpeakingTrue() {
        let controller = TTSController()

        controller.speak("テスト")

        #expect(controller.isSpeaking == true)
    }

    @Test func speak_setsPausedFalse() {
        let controller = TTSController()

        controller.speak("テスト")

        #expect(controller.isPaused == false)
    }

    @Test func speak_updatesSubtitleState() {
        let controller = TTSController()
        let subtitleState = SubtitleState()
        controller.setSubtitleState(subtitleState)

        controller.speak("字幕テキスト")

        #expect(subtitleState.currentText == "字幕テキスト")
    }

    @Test func speak_afterPause_resetsPausedState() {
        let controller = TTSController()
        controller.speak("最初のテキスト")

        // pause()を呼んでからspeak()を呼ぶと、新しい発話が開始される
        controller.pause()
        #expect(controller.isPaused == true)

        controller.speak("新しいテキスト")
        #expect(controller.isPaused == false)
        #expect(controller.isSpeaking == true)
    }

    // MARK: - pause Tests

    @Test func pause_setsPausedTrue_whenSpeaking() {
        let controller = TTSController()
        controller.speak("テスト")

        controller.pause()

        #expect(controller.isPaused == true)
        #expect(controller.isSpeaking == true) // isSpeakingはtrueのまま
    }

    @Test func pause_noOp_whenNotSpeaking() {
        let controller = TTSController()

        controller.pause()

        #expect(controller.isPaused == false)
        #expect(controller.isSpeaking == false)
    }

    @Test func pause_noOp_whenAlreadyPaused() {
        let controller = TTSController()
        controller.speak("テスト")
        controller.pause()

        // 2回目のpause
        controller.pause()

        #expect(controller.isPaused == true)
    }

    // MARK: - resume Tests

    @Test func resume_setsPausedFalse_whenPaused() {
        let controller = TTSController()
        controller.speak("テスト")
        controller.pause()
        #expect(controller.isPaused == true)

        controller.resume()

        #expect(controller.isPaused == false)
    }

    @Test func resume_noOp_whenNotPaused() {
        let controller = TTSController()
        controller.speak("テスト")

        controller.resume()

        // speak後はpausedがfalseなので、resume()は何もしない
        #expect(controller.isPaused == false)
    }

    @Test func resume_noOp_whenNotSpeaking() {
        let controller = TTSController()

        controller.resume()

        #expect(controller.isPaused == false)
        #expect(controller.isSpeaking == false)
    }

    // MARK: - stop Tests

    @Test func stop_setsSpeakingFalse() {
        let controller = TTSController()
        controller.speak("テスト")
        #expect(controller.isSpeaking == true)

        controller.stop()

        #expect(controller.isSpeaking == false)
    }

    @Test func stop_setsPausedFalse() {
        let controller = TTSController()
        controller.speak("テスト")
        controller.pause()
        #expect(controller.isPaused == true)

        controller.stop()

        #expect(controller.isPaused == false)
    }

    @Test func stop_clearsSubtitle() {
        let controller = TTSController()
        let subtitleState = SubtitleState()
        controller.setSubtitleState(subtitleState)
        controller.speak("字幕テキスト")
        #expect(subtitleState.currentText == "字幕テキスト")

        controller.stop()

        #expect(subtitleState.currentText == nil)
    }

    @Test func stop_noOp_whenNotSpeaking() {
        let controller = TTSController()
        let subtitleState = SubtitleState()
        controller.setSubtitleState(subtitleState)

        controller.stop()

        #expect(controller.isSpeaking == false)
        #expect(controller.isPaused == false)
        #expect(subtitleState.currentText == nil)
    }

    // MARK: - Combined Operation Tests

    @Test func speakPauseResumeStop_workflow() {
        let controller = TTSController()
        let subtitleState = SubtitleState()
        controller.setSubtitleState(subtitleState)

        // speak
        controller.speak("テスト")
        #expect(controller.isSpeaking == true)
        #expect(controller.isPaused == false)
        #expect(subtitleState.currentText == "テスト")

        // pause
        controller.pause()
        #expect(controller.isSpeaking == true)
        #expect(controller.isPaused == true)
        #expect(subtitleState.currentText == "テスト") // 字幕は表示継続

        // resume
        controller.resume()
        #expect(controller.isSpeaking == true)
        #expect(controller.isPaused == false)

        // stop
        controller.stop()
        #expect(controller.isSpeaking == false)
        #expect(controller.isPaused == false)
        #expect(subtitleState.currentText == nil)
    }

    @Test func multipleSpeak_stopsCurrentAndStartsNew() {
        let controller = TTSController()
        let subtitleState = SubtitleState()
        controller.setSubtitleState(subtitleState)

        controller.speak("最初のテキスト")
        #expect(subtitleState.currentText == "最初のテキスト")

        controller.speak("次のテキスト")
        #expect(subtitleState.currentText == "次のテキスト")
        #expect(controller.isSpeaking == true)
        #expect(controller.isPaused == false)
    }
}
