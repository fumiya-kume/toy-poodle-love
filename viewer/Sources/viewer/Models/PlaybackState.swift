import Foundation

enum PlaybackState: Equatable, Sendable {
    case stopped
    case ready
    case playing
    case paused
    case error(String)

    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.stopped, .stopped),
             (.ready, .ready),
             (.playing, .playing),
             (.paused, .paused):
            return true
        case let (.error(lhsMessage), .error(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
