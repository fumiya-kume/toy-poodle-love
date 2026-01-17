import Foundation

/// APIリクエストのレート制限を管理
actor RateLimiter {
    private let maxRequests: Int
    private let windowSeconds: TimeInterval
    private var requestTimestamps: [Date] = []

    /// - Parameters:
    ///   - maxRequests: 時間枠内の最大リクエスト数（デフォルト: 45、安全マージンあり）
    ///   - windowSeconds: 時間枠（秒）（デフォルト: 60秒）
    init(maxRequests: Int = 45, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    /// リクエストを許可できるかチェック
    func shouldAllowRequest() -> Bool {
        cleanupOldTimestamps()
        return requestTimestamps.count < maxRequests
    }

    /// リクエストを記録
    func recordRequest() {
        cleanupOldTimestamps()
        requestTimestamps.append(Date())
    }

    /// リクエストを許可できる場合は記録してtrueを返す
    func tryRequest() -> Bool {
        guard shouldAllowRequest() else { return false }
        recordRequest()
        return true
    }

    /// 現在の使用数
    var currentUsage: Int {
        cleanupOldTimestamps()
        return requestTimestamps.count
    }

    /// 残りリクエスト数
    var remainingRequests: Int {
        max(0, maxRequests - currentUsage)
    }

    /// 次のリクエストが可能になるまでの秒数
    var timeUntilNextAvailable: TimeInterval? {
        cleanupOldTimestamps()
        guard requestTimestamps.count >= maxRequests,
              let oldest = requestTimestamps.first else {
            return nil
        }
        let resetTime = oldest.addingTimeInterval(windowSeconds)
        let remaining = resetTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    private func cleanupOldTimestamps() {
        let cutoff = Date().addingTimeInterval(-windowSeconds)
        requestTimestamps.removeAll { $0 < cutoff }
    }
}
