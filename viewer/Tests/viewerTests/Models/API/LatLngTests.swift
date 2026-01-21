import Foundation
import Testing
@testable import VideoOverlayViewer

struct LatLngTests {
    // MARK: - Initialization Tests

    @Test func init_setsLatitudeCorrectly() {
        let latLng = LatLng(latitude: 35.6812, longitude: 139.7671)
        #expect(latLng.latitude == 35.6812)
    }

    @Test func init_setsLongitudeCorrectly() {
        let latLng = LatLng(latitude: 35.6812, longitude: 139.7671)
        #expect(latLng.longitude == 139.7671)
    }

    @Test func init_withZeroCoordinates_works() {
        let latLng = LatLng(latitude: 0, longitude: 0)
        #expect(latLng.latitude == 0)
        #expect(latLng.longitude == 0)
    }

    @Test func init_withNegativeCoordinates_works() {
        let latLng = LatLng(latitude: -33.8688, longitude: -151.2093)
        #expect(latLng.latitude == -33.8688)
        #expect(latLng.longitude == -151.2093)
    }

    // MARK: - Equatable Tests

    @Test func equals_withSameValues_returnsTrue() {
        let latLng1 = LatLng(latitude: 35.6812, longitude: 139.7671)
        let latLng2 = LatLng(latitude: 35.6812, longitude: 139.7671)
        #expect(latLng1 == latLng2)
    }

    @Test func equals_withDifferentLatitude_returnsFalse() {
        let latLng1 = LatLng(latitude: 35.6812, longitude: 139.7671)
        let latLng2 = LatLng(latitude: 35.6813, longitude: 139.7671)
        #expect(latLng1 != latLng2)
    }

    @Test func equals_withDifferentLongitude_returnsFalse() {
        let latLng1 = LatLng(latitude: 35.6812, longitude: 139.7671)
        let latLng2 = LatLng(latitude: 35.6812, longitude: 139.7672)
        #expect(latLng1 != latLng2)
    }

    // MARK: - Codable Tests

    @Test func encode_producesValidJSON() throws {
        let latLng = LatLng(latitude: 35.6812, longitude: 139.7671)
        let data = try JSONEncoder().encode(latLng)
        let json = String(data: data, encoding: .utf8)
        #expect(json != nil)
        #expect(json?.contains("35.6812") == true)
        #expect(json?.contains("139.7671") == true)
    }

    @Test func decode_fromValidJSON_works() throws {
        let json = """
        {"latitude": 35.6812, "longitude": 139.7671}
        """
        let data = json.data(using: .utf8)!
        let latLng = try JSONDecoder().decode(LatLng.self, from: data)
        #expect(latLng.latitude == 35.6812)
        #expect(latLng.longitude == 139.7671)
    }

    @Test func roundTrip_encodeDecode_preservesValues() throws {
        let original = LatLng(latitude: 35.6812, longitude: 139.7671)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LatLng.self, from: data)
        #expect(original == decoded)
    }

    @Test func decode_withIntegerValues_works() throws {
        let json = """
        {"latitude": 35, "longitude": 139}
        """
        let data = json.data(using: .utf8)!
        let latLng = try JSONDecoder().decode(LatLng.self, from: data)
        #expect(latLng.latitude == 35)
        #expect(latLng.longitude == 139)
    }
}
