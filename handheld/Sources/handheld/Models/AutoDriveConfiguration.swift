import Foundation

/// オートドライブの再生速度を表す列挙型。
///
/// Look Aroundによるルートプレビューの進行速度を制御します。
///
/// ## 使用例
///
/// ```swift
/// let speed = AutoDriveSpeed.normal
/// print("間隔: \(speed.intervalSeconds)秒")  // "間隔: 3.0秒"
/// ```
enum AutoDriveSpeed: String, CaseIterable, Identifiable {
    /// 遅い速度（5秒間隔）。景色をゆっくり楽しみたい場合に適しています。
    case slow = "遅い"
    /// 普通速度（3秒間隔）。標準的な再生速度です。デフォルト値です。
    case normal = "普通"
    /// 速い速度（1.5秒間隔）。素早くルートを確認したい場合に適しています。
    case fast = "速い"

    var id: String { rawValue }

    /// シーン切り替えの間隔（秒）。
    var intervalSeconds: Double {
        switch self {
        case .slow: return 5.0
        case .normal: return 3.0
        case .fast: return 1.5
        }
    }

    /// 速度を表すSF Symbolsアイコン名。
    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "car.fill"
        case .fast: return "hare.fill"
        }
    }
}

/// オートドライブの状態を表す列挙型。
///
/// オートドライブ機能の現在の状態を示します。
/// UI側でこの状態に基づいて適切な表示を行います。
enum AutoDriveState: Equatable {
    /// 待機状態。オートドライブが開始されていない。
    case idle
    /// 初期化中。最初のシーンを取得中。
    case initializing(fetchedCount: Int, requiredCount: Int)
    /// 読み込み中。シーンを先読み取得中。
    case loading(progress: Double, fetched: Int, total: Int)
    /// 再生中。
    case playing
    /// 一時停止中。
    case paused
    /// バッファリング中。次のシーンを待機中。
    case buffering
    /// 完了。ルートの終点に到達。
    case completed
    /// 失敗。エラーが発生。
    case failed(message: String)
}

/// オートドライブの設定を管理する構造体。
///
/// 再生速度、状態、先読み設定などを保持します。
///
/// ## 使用例
///
/// ```swift
/// var config = AutoDriveConfiguration()
/// config.speed = .fast
/// print("再生中: \(config.isPlaying)")
/// ```
struct AutoDriveConfiguration {
    /// 再生速度。
    var speed: AutoDriveSpeed = .normal
    /// 現在の状態。
    var state: AutoDriveState = .idle

    /// 初期取得するシーン数。
    let initialFetchCount: Int = 3
    /// 先読み取得するシーン数。
    let prefetchLookahead: Int = 5

    /// 再生中かどうか。
    var isPlaying: Bool {
        state == .playing
    }

    /// 初期化中かどうか。
    var isInitializing: Bool {
        if case .initializing = state { return true }
        return false
    }

    /// バッファリング中かどうか。
    var isBuffering: Bool {
        state == .buffering
    }

    /// アクティブ（待機・完了・失敗以外）かどうか。
    var isActive: Bool {
        switch state {
        case .idle, .completed, .failed:
            return false
        case .initializing, .loading, .playing, .paused, .buffering:
            return true
        }
    }
}
