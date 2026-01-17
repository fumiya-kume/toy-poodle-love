import Foundation
import Observation

/// メイン画面のViewModel。
///
/// 時間帯に応じた挨拶メッセージを管理します。
/// `@Observable`マクロを使用してSwiftUIビューとバインドします。
@Observable
final class ContentViewModel {
    /// 表示するメッセージ。
    var message: String = ""

    /// ViewModelを初期化する。
    ///
    /// - Parameters:
    ///   - now: 現在時刻を取得するクロージャ（テスト用）
    ///   - calendar: 使用するカレンダー
    init(now: () -> Date = Date.init, calendar: Calendar = .current) {
        message = Self.timeBasedGreeting(for: now(), calendar: calendar)
    }

    /// メッセージを更新する。
    ///
    /// - Parameter newMessage: 新しいメッセージ
    func updateMessage(_ newMessage: String) {
        message = newMessage
    }

    private static func timeBasedGreeting(for date: Date, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return "おはようございます！朝のお散歩はいかがですか？"
        case 12..<17:
            return "こんにちは！お散歩を楽しみましょう"
        case 17..<21:
            return "こんばんは！夕方のお散歩タイムですね"
        default:
            return "今日もお疲れさまでした"
        }
    }
}
