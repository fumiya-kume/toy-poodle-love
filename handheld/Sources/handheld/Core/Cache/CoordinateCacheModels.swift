import CoreLocation
import Foundation

/// キャッシュキー: サジェストのtitle + subtitleを正規化
struct SuggestionCacheKey: Hashable, Codable {
    let normalizedTitle: String
    let normalizedSubtitle: String

    init(title: String, subtitle: String) {
        self.normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
        self.normalizedSubtitle = subtitle.lowercased().trimmingCharacters(in: .whitespaces)
    }
}

/// キャッシュエントリ: 座標と作成日時
struct CoordinateCacheEntry: Codable {
    let latitude: Double
    let longitude: Double
    let createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.createdAt = Date()
    }

    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(createdAt) > ttl
    }
}

/// キャッシュ設定
struct CacheConfiguration {
    /// 最大エントリ数
    let maxEntries: Int
    /// TTL（秒）
    let ttlSeconds: TimeInterval
    /// クリーンアップ閾値（この割合に達したらクリーンアップ）
    let cleanupThreshold: Double

    static let `default` = CacheConfiguration(
        maxEntries: 5000,
        ttlSeconds: 7 * 24 * 60 * 60,  // 7日
        cleanupThreshold: 0.9
    )

    var cleanupEntryCount: Int {
        Int(Double(maxEntries) * cleanupThreshold)
    }
}
