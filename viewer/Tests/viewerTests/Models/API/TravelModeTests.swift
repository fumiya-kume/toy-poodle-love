import Foundation
import Testing
@testable import VideoOverlayViewer

struct TravelModeTests {
    // MARK: - Raw Value Tests

    @Test func driving_hasCorrectRawValue() {
        #expect(TravelMode.driving.rawValue == "DRIVE")
    }

    @Test func walking_hasCorrectRawValue() {
        #expect(TravelMode.walking.rawValue == "WALK")
    }

    @Test func bicycling_hasCorrectRawValue() {
        #expect(TravelMode.bicycling.rawValue == "BICYCLE")
    }

    @Test func transit_hasCorrectRawValue() {
        #expect(TravelMode.transit.rawValue == "TRANSIT")
    }

    // MARK: - Display Name Tests

    @Test func driving_hasCorrectDisplayName() {
        #expect(TravelMode.driving.displayName == "車")
    }

    @Test func walking_hasCorrectDisplayName() {
        #expect(TravelMode.walking.displayName == "徒歩")
    }

    @Test func bicycling_hasCorrectDisplayName() {
        #expect(TravelMode.bicycling.displayName == "自転車")
    }

    @Test func transit_hasCorrectDisplayName() {
        #expect(TravelMode.transit.displayName == "公共交通機関")
    }

    // MARK: - Identifiable Tests

    @Test func driving_idMatchesRawValue() {
        #expect(TravelMode.driving.id == "DRIVE")
    }

    @Test func walking_idMatchesRawValue() {
        #expect(TravelMode.walking.id == "WALK")
    }

    @Test func bicycling_idMatchesRawValue() {
        #expect(TravelMode.bicycling.id == "BICYCLE")
    }

    @Test func transit_idMatchesRawValue() {
        #expect(TravelMode.transit.id == "TRANSIT")
    }

    // MARK: - CaseIterable Tests

    @Test func allCases_containsAllModes() {
        #expect(TravelMode.allCases.count == 4)
        #expect(TravelMode.allCases.contains(.driving))
        #expect(TravelMode.allCases.contains(.walking))
        #expect(TravelMode.allCases.contains(.bicycling))
        #expect(TravelMode.allCases.contains(.transit))
    }

    // MARK: - Codable Tests

    @Test func encode_driving_producesCorrectJSON() throws {
        let data = try JSONEncoder().encode(TravelMode.driving)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "\"DRIVE\"")
    }

    @Test func decode_driving_fromJSON() throws {
        let json = "\"DRIVE\""
        let data = json.data(using: .utf8)!
        let mode = try JSONDecoder().decode(TravelMode.self, from: data)
        #expect(mode == .driving)
    }

    @Test func decode_walking_fromJSON() throws {
        let json = "\"WALK\""
        let data = json.data(using: .utf8)!
        let mode = try JSONDecoder().decode(TravelMode.self, from: data)
        #expect(mode == .walking)
    }

    @Test func decode_bicycling_fromJSON() throws {
        let json = "\"BICYCLE\""
        let data = json.data(using: .utf8)!
        let mode = try JSONDecoder().decode(TravelMode.self, from: data)
        #expect(mode == .bicycling)
    }

    @Test func decode_transit_fromJSON() throws {
        let json = "\"TRANSIT\""
        let data = json.data(using: .utf8)!
        let mode = try JSONDecoder().decode(TravelMode.self, from: data)
        #expect(mode == .transit)
    }
}
