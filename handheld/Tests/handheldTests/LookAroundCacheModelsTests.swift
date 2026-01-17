import CoreLocation
import Foundation
import Testing
@testable import handheld

// MARK: - LookAroundCacheKey Tests

struct LookAroundCacheKeyTests {
    @Test func init_roundsCoordinatesToPrecision() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.68123456789, longitude: 139.76712345678)
        let key = LookAroundCacheKey(coordinate: coordinate, precision: 5)

        #expect(key.latitude == 35.68123)
        #expect(key.longitude == 139.76712)
    }

    @Test func init_defaultPrecisionIs5() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.68123456789, longitude: 139.76712345678)
        let key = LookAroundCacheKey(coordinate: coordinate)

        #expect(key.latitude == 35.68123)
        #expect(key.longitude == 139.76712)
    }

    @Test func init_precision3_roundsToThreeDecimals() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.68123456789, longitude: 139.76712345678)
        let key = LookAroundCacheKey(coordinate: coordinate, precision: 3)

        #expect(key.latitude == 35.681)
        #expect(key.longitude == 139.767)
    }

    @Test func hashable_sameCoordinates_sameHash() {
        let coord1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let coord2 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let key1 = LookAroundCacheKey(coordinate: coord1)
        let key2 = LookAroundCacheKey(coordinate: coord2)

        #expect(key1 == key2)
        #expect(key1.hashValue == key2.hashValue)
    }

    @Test func hashable_differentCoordinates_differentHash() {
        let coord1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let coord2 = CLLocationCoordinate2D(latitude: 35.6813, longitude: 139.7672)
        let key1 = LookAroundCacheKey(coordinate: coord1)
        let key2 = LookAroundCacheKey(coordinate: coord2)

        #expect(key1 != key2)
    }

    @Test func description_formatsCorrectly() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let key = LookAroundCacheKey(coordinate: coordinate)

        #expect(key.description.contains("35.6812"))
        #expect(key.description.contains("139.7671"))
    }

    @Test func codable_encodesAndDecodes() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let original = LookAroundCacheKey(coordinate: coordinate)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(LookAroundCacheKey.self, from: data)

        #expect(decoded.latitude == original.latitude)
        #expect(decoded.longitude == original.longitude)
    }
}

// MARK: - LookAroundAvailabilityEntry Tests

struct LookAroundAvailabilityEntryTests {
    @Test func init_setsIsAvailable() {
        let entryAvailable = LookAroundAvailabilityEntry(isAvailable: true)
        let entryNotAvailable = LookAroundAvailabilityEntry(isAvailable: false)

        #expect(entryAvailable.isAvailable == true)
        #expect(entryNotAvailable.isAvailable == false)
    }

    @Test func init_setsCreatedAtToNow() {
        let before = Date()
        let entry = LookAroundAvailabilityEntry(isAvailable: true)
        let after = Date()

        #expect(entry.createdAt >= before)
        #expect(entry.createdAt <= after)
    }

    @Test func isExpired_notExpired_returnsFalse() {
        let entry = LookAroundAvailabilityEntry(isAvailable: true)
        let ttl: TimeInterval = 60 * 60 // 1 hour

        #expect(entry.isExpired(ttl: ttl) == false)
    }

    @Test func codable_encodesAndDecodes() throws {
        let original = LookAroundAvailabilityEntry(isAvailable: true)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(LookAroundAvailabilityEntry.self, from: data)

        #expect(decoded.isAvailable == original.isAvailable)
    }
}

// MARK: - LookAroundCacheConfiguration Tests

struct LookAroundCacheConfigurationTests {
    @Test func default_hasCorrectValues() {
        let config = LookAroundCacheConfiguration.default

        #expect(config.maxAvailabilityEntries == 10000)
        #expect(config.maxSceneEntries == 500)
        #expect(config.ttlSeconds == 30 * 24 * 60 * 60) // 30 days
        #expect(config.cleanupThreshold == 0.9)
    }

    @Test func cleanupEntryCount_calculatesCorrectly() {
        let config = LookAroundCacheConfiguration.default

        #expect(config.cleanupEntryCount == 9000) // 10000 * 0.9
    }

    @Test func customConfiguration_setsCorrectValues() {
        let config = LookAroundCacheConfiguration(
            maxAvailabilityEntries: 5000,
            maxSceneEntries: 100,
            ttlSeconds: 7 * 24 * 60 * 60,
            cleanupThreshold: 0.8
        )

        #expect(config.maxAvailabilityEntries == 5000)
        #expect(config.maxSceneEntries == 100)
        #expect(config.ttlSeconds == 7 * 24 * 60 * 60)
        #expect(config.cleanupThreshold == 0.8)
        #expect(config.cleanupEntryCount == 4000) // 5000 * 0.8
    }
}
