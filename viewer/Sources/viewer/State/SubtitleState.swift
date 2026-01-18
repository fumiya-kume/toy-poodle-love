import Foundation
import Observation

/// 字幕表示の状態を管理
@Observable
@MainActor
final class SubtitleState {
    /// 現在表示中のテキスト（nilの場合は非表示）
    private(set) var currentText: String?

    /// 字幕を表示
    func show(_ text: String) {
        currentText = text
    }

    /// 字幕を消去
    func clear() {
        currentText = nil
    }
}
