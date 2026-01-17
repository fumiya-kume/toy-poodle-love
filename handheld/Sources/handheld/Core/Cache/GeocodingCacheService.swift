import CoreLocation
import Foundation
import os

/// ジオコーディング結果をキャッシュするサービス
actor GeocodingCacheService {
    private var memoryCache: [SuggestionCacheKey: CoordinateCacheEntry] = [:]
    private let configuration: CacheConfiguration
    private let cacheFileURL: URL
    private var isDirty = false
    private var saveTask: Task<Void, Never>?
    private let saveDebounce: Duration = .milliseconds(300)

    init(configuration: CacheConfiguration = .default) {
        self.configuration = configuration
        self.cacheFileURL = Self.defaultCacheFileURL()

        Task.detached { [self] in
            await loadCache()
        }
    }

    // MARK: - Public API

    /// キャッシュから座標を取得
    func coordinate(for title: String, subtitle: String) -> CLLocationCoordinate2D? {
        let key = SuggestionCacheKey(title: title, subtitle: subtitle)

        guard let entry = memoryCache[key] else {
            AppLogger.cache.debug("キャッシュミス: \(title)")
            return nil
        }

        if entry.isExpired(ttl: configuration.ttlSeconds) {
            memoryCache.removeValue(forKey: key)
            isDirty = true
            AppLogger.cache.debug("キャッシュ期限切れ: \(title)")
            return nil
        }

        AppLogger.cache.debug("キャッシュヒット: \(title)")
        return entry.coordinate
    }

    /// 座標をキャッシュに保存
    func cacheCoordinate(_ coordinate: CLLocationCoordinate2D, for title: String, subtitle: String) {
        let key = SuggestionCacheKey(title: title, subtitle: subtitle)
        let entry = CoordinateCacheEntry(coordinate: coordinate)

        memoryCache[key] = entry
        isDirty = true

        if memoryCache.count >= configuration.cleanupEntryCount {
            cleanupOldEntries()
        }

        scheduleSave()

        AppLogger.cache.debug("キャッシュ保存: \(title) (\(coordinate.latitude), \(coordinate.longitude))")
    }

    /// キャッシュをクリア
    func clearCache() {
        memoryCache.removeAll()
        isDirty = true
        saveTask?.cancel()
        saveTask = nil
        scheduleSave()
        AppLogger.cache.info("キャッシュをクリアしました")
    }

    /// キャッシュ統計情報
    var statistics: CacheStatistics {
        CacheStatistics(
            totalEntries: memoryCache.count,
            maxEntries: configuration.maxEntries
        )
    }

    // MARK: - Private Methods

    private static func defaultCacheFileURL() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return cacheDirectory.appendingPathComponent("geocoding_cache.json")
    }

    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            AppLogger.cache.info("キャッシュファイルが存在しません。新規作成します。")
            return
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cached = try decoder.decode([SuggestionCacheKey: CoordinateCacheEntry].self, from: data)

            // 期限切れエントリを除外してロード
            memoryCache = cached.filter { !$0.value.isExpired(ttl: configuration.ttlSeconds) }
            AppLogger.cache.info("キャッシュをロードしました: \(self.memoryCache.count)件")
        } catch {
            AppLogger.cache.error("キャッシュのロードに失敗しました: \(error.localizedDescription)")
        }
    }

    private func saveCache() async {
        guard isDirty else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(memoryCache)
            try data.write(to: cacheFileURL, options: .atomic)
            isDirty = false
            AppLogger.cache.debug("キャッシュを保存しました: \(self.memoryCache.count)件")
        } catch {
            AppLogger.cache.error("キャッシュの保存に失敗しました: \(error.localizedDescription)")
        }
    }

    private func scheduleSave() {
        guard saveTask == nil else { return }

        saveTask = Task.detached { [self] in
            try? await Task.sleep(for: saveDebounce)
            await saveCache()
            await clearSaveTask()
        }
    }

    private func clearSaveTask() {
        saveTask = nil
    }

    private func cleanupOldEntries() {
        // 期限切れエントリを削除
        let beforeCount = memoryCache.count
        memoryCache = memoryCache.filter { !$0.value.isExpired(ttl: configuration.ttlSeconds) }

        // まだ多い場合は古い順に削除
        if memoryCache.count > configuration.maxEntries {
            let sortedEntries = memoryCache.sorted { $0.value.createdAt < $1.value.createdAt }
            let entriesToRemove = memoryCache.count - configuration.maxEntries
            for entry in sortedEntries.prefix(entriesToRemove) {
                memoryCache.removeValue(forKey: entry.key)
            }
        }

        let removedCount = beforeCount - memoryCache.count
        if removedCount > 0 {
            isDirty = true
            AppLogger.cache.info("古いキャッシュを削除しました: \(removedCount)件")
        }
    }
}

/// キャッシュ統計情報
struct CacheStatistics {
    let totalEntries: Int
    let maxEntries: Int

    var usagePercentage: Double {
        guard maxEntries > 0 else { return 0 }
        return Double(totalEntries) / Double(maxEntries) * 100
    }
}
