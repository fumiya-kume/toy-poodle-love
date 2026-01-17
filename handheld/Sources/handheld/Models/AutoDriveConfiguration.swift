import Foundation

enum AutoDriveSpeed: String, CaseIterable, Identifiable {
    case slow = "遅い"
    case normal = "普通"
    case fast = "速い"

    var id: String { rawValue }

    var intervalSeconds: Double {
        switch self {
        case .slow: return 5.0
        case .normal: return 3.0
        case .fast: return 1.5
        }
    }

    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "car.fill"
        case .fast: return "hare.fill"
        }
    }
}

enum AutoDriveState: Equatable {
    case idle
    case loading(progress: Double, fetched: Int, total: Int)
    case playing
    case paused
    case completed
    case failed(message: String)
}

struct AutoDriveConfiguration {
    var speed: AutoDriveSpeed = .normal
    var state: AutoDriveState = .idle
    var minimumSuccessRate: Double = 0.30

    var isPlaying: Bool {
        state == .playing
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var isActive: Bool {
        switch state {
        case .idle, .completed, .failed:
            return false
        case .loading, .playing, .paused:
            return true
        }
    }
}
