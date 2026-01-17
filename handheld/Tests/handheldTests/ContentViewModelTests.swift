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
        #expect(viewModel.message == "Hello, Toy Poodle Love!")
    }
}
