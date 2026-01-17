import CoreLocation
import Foundation

/// Look Aroundキャッシュのキー
/// 座標を指定精度に丸めてハッシュ可能にする
struct LookAroundCacheKey: Hashable, Codable {
    let latitude: Double
    let longitude: Double

    /// 座標からキャッシュキーを生成
    /// - Parameters:
    ///   - coordinate: 元の座標
    ///   - precision: 小数点以下の桁数（デフォルト: 5 = 約1.1m精度）
    init(coordinate: CLLocationCoordinate2D, precision: Int = 5) {
        let multiplier = pow(10.0, Double(precision))
        self.latitude = (coordinate.latitude * multiplier).rounded() / multiplier
        self.longitude = (coordinate.longitude * multiplier).rounded() / multiplier
    }

    /// デバッグ用の文字列表現
    var description: String {
        "\(latitude)_\(longitude)"
    }
}

/// Look Aroundシーンの可用性エントリ
struct LookAroundAvailabilityEntry: Codable {
    /// シーンが利用可能かどうか
    let isAvailable: Bool
    /// キャッシュ作成日時
    let createdAt: Date

    init(isAvailable: Bool) {
        self.isAvailable = isAvailable
        self.createdAt = Date()
    }

    /// 指定TTLで期限切れかどうか
    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(createdAt) > ttl
    }
}

/// Look Aroundキャッシュ設定
struct LookAroundCacheConfiguration {
    /// 可用性キャッシュの最大エントリ数
    let maxAvailabilityEntries: Int
    /// メモリキャッシュの最大エントリ数
    let maxSceneEntries: Int
    /// TTL（秒）
    let ttlSeconds: TimeInterval
    /// クリーンアップ閾値
    let cleanupThreshold: Double

    static let `default` = LookAroundCacheConfiguration(
        maxAvailabilityEntries: 10000,
        maxSceneEntries: 500,
        ttlSeconds: 30 * 24 * 60 * 60,  // 30日
        cleanupThreshold: 0.9
    )

    var cleanupEntryCount: Int {
        Int(Double(maxAvailabilityEntries) * cleanupThreshold)
    }
}
