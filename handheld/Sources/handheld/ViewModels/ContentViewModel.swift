import Foundation
import Observation

@Observable
final class ContentViewModel {
    var message: String = ""

    init(now: () -> Date = Date.init, calendar: Calendar = .current) {
        message = Self.timeBasedGreeting(for: now(), calendar: calendar)
    }

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
