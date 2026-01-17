import CoreLocation
import Foundation
import MapKit
import os

/// Look Aroundシーンをキャッシュするサービス
/// - L1: メモリキャッシュ（MKLookAroundSceneオブジェクト、TTL付き）
/// - L2: 可用性キャッシュ（Bool、ファイル永続化）
actor LookAroundCacheService {

    // MARK: - Types

    /// L1: メモリキャッシュエントリ（タイムスタンプ付き）
    private struct SceneCacheEntry {
        let scene: MKLookAroundScene
        let createdAt: Date

        func isExpired(ttl: TimeInterval) -> Bool {
            Date().timeIntervalSince(createdAt) > ttl
        }
    }

    // MARK: - Properties

    /// L1: メモリキャッシュ（TTL付き）
    private var sceneCache: [LookAroundCacheKey: SceneCacheEntry] = [:]

    /// メモリキャッシュの TTL (デフォルト 1 時間)
    private let memoryCacheTTL: TimeInterval = 3600

    /// L2: 可用性キャッシュ（永続化対象）
    private var availabilityCache: [LookAroundCacheKey: LookAroundAvailabilityEntry] = [:]

    private let configuration: LookAroundCacheConfiguration
    private let cacheFileURL: URL
    private var isDirty = false
    private var saveTask: Task<Void, Never>?
    private let saveDebounce: Duration = .milliseconds(300)

    // MARK: - Statistics

    private var memoryHitCount = 0
    private var availabilityHitCount = 0
    private var missCount = 0

    // MARK: - Initialization

    init(configuration: LookAroundCacheConfiguration = .default) {
        self.configuration = configuration
        self.cacheFileURL = Self.defaultCacheFileURL()

        Task {
            await loadAvailabilityCache()
        }
    }

    // MARK: - Public API

    /// メモリキャッシュからシーンを取得
    func cachedScene(for coordinate: CLLocationCoordinate2D) -> MKLookAroundScene? {
        let key = LookAroundCacheKey(coordinate: coordinate)

        if let entry = sceneCache[key] {
            // TTL チェック
            if entry.isExpired(ttl: memoryCacheTTL) {
                sceneCache.removeValue(forKey: key)
                AppLogger.cache.debug("Look Aroundメモリキャッシュ期限切れ: \(key.description)")
                return nil
            }

            memoryHitCount += 1
            AppLogger.cache.debug("Look Aroundメモリキャッシュヒット: \(key.description)")
            return entry.scene
        }

        return nil
    }

    /// 指定座標がシーン利用不可と記録されているか確認
    func isKnownUnavailable(for coordinate: CLLocationCoordinate2D) -> Bool {
        let key = LookAroundCacheKey(coordinate: coordinate)

        guard let entry = availabilityCache[key] else {
            return false
        }

        if entry.isExpired(ttl: configuration.ttlSeconds) {
            availabilityCache.removeValue(forKey: key)
            isDirty = true
            AppLogger.cache.debug("Look Around可用性キャッシュ期限切れ: \(key.description)")
            return false
        }

        if !entry.isAvailable {
            availabilityHitCount += 1
            AppLogger.cache.debug("Look Around利用不可キャッシュヒット: \(key.description)")
            return true
        }

        return false
    }

    /// シーンをキャッシュに保存
    func cacheScene(_ scene: MKLookAroundScene?, for coordinate: CLLocationCoordinate2D) {
        let key = LookAroundCacheKey(coordinate: coordinate)
        let isAvailable = scene != nil

        // L1: メモリキャッシュに保存（シーンがある場合のみ）
        if let scene = scene {
            if sceneCache.count >= configuration.maxSceneEntries {
                evictOldestScenes(count: configuration.maxSceneEntries / 10)
            }
            sceneCache[key] = SceneCacheEntry(scene: scene, createdAt: Date())
            AppLogger.cache.debug("Look Aroundシーンをメモリキャッシュに保存: \(key.description)")
        }

        // L2: 可用性キャッシュに保存
        availabilityCache[key] = LookAroundAvailabilityEntry(isAvailable: isAvailable)
        isDirty = true
        missCount += 1

        if availabilityCache.count >= configuration.cleanupEntryCount {
            cleanupOldEntries()
        }

        scheduleSave()

        let status = isAvailable ? "利用可能" : "利用不可"
        AppLogger.cache.debug("Look Around可用性をキャッシュに保存: \(key.description) (\(status))")
    }

    /// キャッシュ統計情報を取得
    var statistics: LookAroundCacheStatistics {
        LookAroundCacheStatistics(
            sceneCacheCount: sceneCache.count,
            availabilityCacheCount: availabilityCache.count,
            memoryHitCount: memoryHitCount,
            availabilityHitCount: availabilityHitCount,
            missCount: missCount
        )
    }

    /// キャッシュをクリア
    func clearCache() {
        sceneCache.removeAll()
        availabilityCache.removeAll()
        memoryHitCount = 0
        availabilityHitCount = 0
        missCount = 0
        isDirty = true

        saveTask?.cancel()
        saveTask = nil
        scheduleSave()

        AppLogger.cache.info("Look Aroundキャッシュをクリアしました")
    }

    // MARK: - Private Methods

    private static func defaultCacheFileURL() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return cacheDirectory.appendingPathComponent("lookaround_availability_cache.json")
    }

    private func loadAvailabilityCache() {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            AppLogger.cache.info("Look Around可用性キャッシュファイルが存在しません。新規作成します。")
            return
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cached = try decoder.decode([LookAroundCacheKey: LookAroundAvailabilityEntry].self, from: data)

            availabilityCache = cached.filter { !$0.value.isExpired(ttl: configuration.ttlSeconds) }
            AppLogger.cache.info("Look Around可用性キャッシュをロードしました: \(self.availabilityCache.count)件")
        } catch {
            AppLogger.cache.error("Look Around可用性キャッシュのロードに失敗しました: \(error.localizedDescription)")
        }
    }

    private func saveAvailabilityCache() async {
        guard isDirty else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(availabilityCache)
            try data.write(to: cacheFileURL, options: .atomic)
            isDirty = false
            AppLogger.cache.debug("Look Around可用性キャッシュを保存しました: \(self.availabilityCache.count)件")
        } catch {
            AppLogger.cache.error("Look Around可用性キャッシュの保存に失敗しました: \(error.localizedDescription)")
        }
    }

    private func scheduleSave() {
        guard saveTask == nil else { return }

        saveTask = Task {
            try? await Task.sleep(for: saveDebounce)
            await saveAvailabilityCache()
            await clearSaveTask()
        }
    }

    private func clearSaveTask() {
        saveTask = nil
    }

    private func cleanupOldEntries() {
        let beforeCount = availabilityCache.count

        availabilityCache = availabilityCache.filter { !$0.value.isExpired(ttl: configuration.ttlSeconds) }

        if availabilityCache.count > configuration.maxAvailabilityEntries {
            let sortedEntries = availabilityCache.sorted { $0.value.createdAt < $1.value.createdAt }
            let entriesToRemove = availabilityCache.count - configuration.maxAvailabilityEntries
            for entry in sortedEntries.prefix(entriesToRemove) {
                availabilityCache.removeValue(forKey: entry.key)
            }
        }

        let removedCount = beforeCount - availabilityCache.count
        if removedCount > 0 {
            isDirty = true
            AppLogger.cache.info("古いLook Around可用性キャッシュを削除しました: \(removedCount)件")
        }
    }

    private func evictOldestScenes(count: Int) {
        // まず期限切れエントリを削除
        let expiredKeys = sceneCache.filter { $0.value.isExpired(ttl: memoryCacheTTL) }.keys
        for key in expiredKeys {
            sceneCache.removeValue(forKey: key)
        }

        // まだ超過している場合は古い順に削除
        if sceneCache.count >= configuration.maxSceneEntries {
            let sortedKeys = sceneCache.sorted { $0.value.createdAt < $1.value.createdAt }
                .prefix(count)
                .map { $0.key }
            for key in sortedKeys {
                sceneCache.removeValue(forKey: key)
            }
        }

        AppLogger.cache.debug("メモリキャッシュからシーンを削除しました")
    }
}

/// キャッシュ統計情報
struct LookAroundCacheStatistics {
    let sceneCacheCount: Int
    let availabilityCacheCount: Int
    let memoryHitCount: Int
    let availabilityHitCount: Int
    let missCount: Int

    var totalRequests: Int {
        memoryHitCount + availabilityHitCount + missCount
    }

    var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHitCount + availabilityHitCount) / Double(totalRequests) * 100
    }
}
