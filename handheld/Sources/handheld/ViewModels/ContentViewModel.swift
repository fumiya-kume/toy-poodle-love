import Foundation
import Observation

@Observable
class ContentViewModel {
    var message: String = "Hello, Toy Poodle Love!"

    func updateMessage(_ newMessage: String) {
        message = newMessage
    }
}
