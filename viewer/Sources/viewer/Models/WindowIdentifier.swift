import Foundation

enum WindowIdentifier: String, CaseIterable, Identifiable, Sendable {
    case video1 = "video-window-1"
    case video2 = "video-window-2"
    case video3 = "video-window-3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .video1: return "Video Window 1"
        case .video2: return "Video Window 2"
        case .video3: return "Video Window 3"
        }
    }

    var index: Int {
        switch self {
        case .video1: return 0
        case .video2: return 1
        case .video3: return 2
        }
    }

    static func from(index: Int) -> WindowIdentifier? {
        switch index {
        case 0: return .video1
        case 1: return .video2
        case 2: return .video3
        default: return nil
        }
    }
}
