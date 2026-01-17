import CoreLocation
import Foundation
import Testing
@testable import handheld

// MARK: - RateLimiter Tests

struct RateLimiterTests {
    @Test func shouldAllowRequestWhenUnderLimit() async {
        let limiter = RateLimiter(maxRequests: 3, windowSeconds: 60)
        let allowed = await limiter.shouldAllowRequest()
        #expect(allowed == true)
    }

    @Test func shouldBlockRequestWhenAtLimit() async {
        let limiter = RateLimiter(maxRequests: 3, windowSeconds: 60)

        // 3回リクエストを記録
        for _ in 0..<3 {
            await limiter.recordRequest()
        }

        let allowed = await limiter.shouldAllowRequest()
        #expect(allowed == false)
    }

    @Test func remainingRequestsDecreasesWithUsage() async {
        let limiter = RateLimiter(maxRequests: 5, windowSeconds: 60)

        #expect(await limiter.remainingRequests == 5)

        await limiter.recordRequest()
        #expect(await limiter.remainingRequests == 4)

        await limiter.recordRequest()
        #expect(await limiter.remainingRequests == 3)
    }

    @Test func tryRequestRecordsAndReturnsTrue() async {
        let limiter = RateLimiter(maxRequests: 2, windowSeconds: 60)

        let first = await limiter.tryRequest()
        #expect(first == true)
        #expect(await limiter.remainingRequests == 1)

        let second = await limiter.tryRequest()
        #expect(second == true)
        #expect(await limiter.remainingRequests == 0)

        let third = await limiter.tryRequest()
        #expect(third == false)
    }

    @Test func currentUsageTracksRequests() async {
        let limiter = RateLimiter(maxRequests: 10, windowSeconds: 60)

        #expect(await limiter.currentUsage == 0)

        await limiter.recordRequest()
        await limiter.recordRequest()
        await limiter.recordRequest()

        #expect(await limiter.currentUsage == 3)
    }
}

// MARK: - CoordinateCacheModels Tests

struct CoordinateCacheModelsTests {
    @Test func suggestionCacheKeyNormalization() {
        let key1 = SuggestionCacheKey(title: "Tokyo Station", subtitle: "Tokyo, Japan")
        let key2 = SuggestionCacheKey(title: "tokyo station", subtitle: "tokyo, japan")
        let key3 = SuggestionCacheKey(title: "  Tokyo Station  ", subtitle: "  Tokyo, Japan  ")

        #expect(key1 == key2)
        #expect(key1 == key3)
        #expect(key1.hashValue == key2.hashValue)
    }

    @Test func suggestionCacheKeyDifference() {
        let key1 = SuggestionCacheKey(title: "Tokyo Station", subtitle: "Tokyo")
        let key2 = SuggestionCacheKey(title: "Osaka Station", subtitle: "Osaka")

        #expect(key1 != key2)
    }

    @Test func coordinateCacheEntryStoresCoordinate() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let entry = CoordinateCacheEntry(coordinate: coordinate)

        #expect(entry.latitude == 35.6812)
        #expect(entry.longitude == 139.7671)
        #expect(entry.coordinate.latitude == coordinate.latitude)
        #expect(entry.coordinate.longitude == coordinate.longitude)
    }

    @Test func coordinateCacheEntryNotExpiredWhenFresh() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let entry = CoordinateCacheEntry(coordinate: coordinate)

        // 7日のTTLでは期限切れにならない
        #expect(entry.isExpired(ttl: 7 * 24 * 60 * 60) == false)
    }

    @Test func cacheConfigurationDefaults() {
        let config = CacheConfiguration.default

        #expect(config.maxEntries == 5000)
        #expect(config.ttlSeconds == 7 * 24 * 60 * 60)
        #expect(config.cleanupThreshold == 0.9)
        #expect(config.cleanupEntryCount == 4500)
    }
}

// MARK: - GeocodingCacheService Tests

struct GeocodingCacheServiceTests {
    @Test func cacheHit() async {
        let config = CacheConfiguration(maxEntries: 100, ttlSeconds: 3600, cleanupThreshold: 0.9)
        let cache = GeocodingCacheService(configuration: config)
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        await cache.cacheCoordinate(coordinate, for: "東京駅", subtitle: "東京都千代田区")
        let result = await cache.coordinate(for: "東京駅", subtitle: "東京都千代田区")

        #expect(result != nil)
        #expect(result?.latitude == coordinate.latitude)
        #expect(result?.longitude == coordinate.longitude)
    }

    @Test func cacheMiss() async {
        let config = CacheConfiguration(maxEntries: 100, ttlSeconds: 3600, cleanupThreshold: 0.9)
        let cache = GeocodingCacheService(configuration: config)

        let result = await cache.coordinate(for: "存在しない場所", subtitle: "どこか")

        #expect(result == nil)
    }

    @Test func cacheKeyNormalizationWorks() async {
        let config = CacheConfiguration(maxEntries: 100, ttlSeconds: 3600, cleanupThreshold: 0.9)
        let cache = GeocodingCacheService(configuration: config)
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        // 大文字で保存
        await cache.cacheCoordinate(coordinate, for: "TOKYO STATION", subtitle: "TOKYO")

        // 小文字で取得
        let result = await cache.coordinate(for: "tokyo station", subtitle: "tokyo")

        #expect(result != nil)
    }

    @Test func clearCacheRemovesAllEntries() async {
        let config = CacheConfiguration(maxEntries: 100, ttlSeconds: 3600, cleanupThreshold: 0.9)
        let cache = GeocodingCacheService(configuration: config)
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        await cache.cacheCoordinate(coordinate, for: "東京駅", subtitle: "東京都")
        await cache.cacheCoordinate(coordinate, for: "大阪駅", subtitle: "大阪府")

        let statsBefore = await cache.statistics
        #expect(statsBefore.totalEntries == 2)

        await cache.clearCache()

        let statsAfter = await cache.statistics
        #expect(statsAfter.totalEntries == 0)
    }

    @Test func statisticsReportsCorrectly() async {
        let config = CacheConfiguration(maxEntries: 100, ttlSeconds: 3600, cleanupThreshold: 0.9)
        let cache = GeocodingCacheService(configuration: config)
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let initialStats = await cache.statistics
        #expect(initialStats.totalEntries == 0)
        #expect(initialStats.maxEntries == 100)

        await cache.cacheCoordinate(coordinate, for: "東京駅", subtitle: "東京都")

        let updatedStats = await cache.statistics
        #expect(updatedStats.totalEntries == 1)
        #expect(updatedStats.usagePercentage == 1.0)
    }
}
