import Testing
@testable import handheld

struct ContentViewModelTests {
    @Test func updateMessage() {
        let viewModel = ContentViewModel()
        viewModel.updateMessage("New Message")
        #expect(viewModel.message == "New Message")
    }

    @Test func initialMessage() {
        let viewModel = ContentViewModel()
        let validMessages = [
            "おはようございます！朝のお散歩はいかがですか？",
            "こんにちは！お散歩を楽しみましょう",
            "こんばんは！夕方のお散歩タイムですね",
            "今日もお疲れさまでした"
        ]
        #expect(validMessages.contains(viewModel.message))
    }
}
