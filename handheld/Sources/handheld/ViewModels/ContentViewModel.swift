import Foundation
import Observation

@Observable
class ContentViewModel {
    var message: String = ""

    init() {
        message = getTimeBasedGreeting()
    }

    func updateMessage(_ newMessage: String) {
        message = newMessage
    }

    func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
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
