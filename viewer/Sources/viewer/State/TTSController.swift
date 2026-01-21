import AVFoundation
import Observation

/// Text-to-Speech を制御するコントローラー
@Observable
@MainActor
final class TTSController: NSObject {
    /// 再生中かどうか
    private(set) var isSpeaking = false

    /// 一時停止中かどうか
    private(set) var isPaused = false

    /// 字幕状態への参照
    private weak var subtitleState: SubtitleState?

    private let synthesizer = AVSpeechSynthesizer()
    private var currentText: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// 字幕状態を設定
    func setSubtitleState(_ state: SubtitleState) {
        self.subtitleState = state
    }

    /// テキストを読み上げ、字幕を表示
    func speak(_ text: String) {
        stop()

        currentText = text
        subtitleState?.show(text)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    /// 一時停止（字幕は表示継続）
    func pause() {
        guard isSpeaking, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        isPaused = true
    }

    /// 再開
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    /// 停止、字幕消去
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentText = nil
        subtitleState?.clear()
    }
}

extension TTSController: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        MainActor.assumeIsolated {
            self.isSpeaking = false
            self.isPaused = false
            self.currentText = nil
            self.subtitleState?.clear()
        }
    }
}
