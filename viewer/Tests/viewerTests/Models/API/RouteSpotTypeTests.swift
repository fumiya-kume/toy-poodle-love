import Foundation
import Testing
@testable import VideoOverlayViewer

struct RouteSpotTypeTests {
    // MARK: - Raw Value Tests

    @Test func start_hasCorrectRawValue() {
        #expect(RouteSpotType.start.rawValue == "start")
    }

    @Test func waypoint_hasCorrectRawValue() {
        #expect(RouteSpotType.waypoint.rawValue == "waypoint")
    }

    @Test func destination_hasCorrectRawValue() {
        #expect(RouteSpotType.destination.rawValue == "destination")
    }

    // MARK: - Display Name Tests

    @Test func start_hasCorrectDisplayName() {
        #expect(RouteSpotType.start.displayName == "出発")
    }

    @Test func waypoint_hasCorrectDisplayName() {
        #expect(RouteSpotType.waypoint.displayName == "経由")
    }

    @Test func destination_hasCorrectDisplayName() {
        #expect(RouteSpotType.destination.displayName == "到着")
    }

    // MARK: - Identifiable Tests

    @Test func start_idMatchesRawValue() {
        #expect(RouteSpotType.start.id == "start")
    }

    @Test func waypoint_idMatchesRawValue() {
        #expect(RouteSpotType.waypoint.id == "waypoint")
    }

    @Test func destination_idMatchesRawValue() {
        #expect(RouteSpotType.destination.id == "destination")
    }

    // MARK: - CaseIterable Tests

    @Test func allCases_containsAllTypes() {
        #expect(RouteSpotType.allCases.count == 3)
        #expect(RouteSpotType.allCases.contains(.start))
        #expect(RouteSpotType.allCases.contains(.waypoint))
        #expect(RouteSpotType.allCases.contains(.destination))
    }

    // MARK: - fromGeneratedType Tests

    @Test func fromGeneratedType_start_returnsStart() {
        #expect(RouteSpotType.fromGeneratedType("start") == .start)
    }

    @Test func fromGeneratedType_intermediate_returnsWaypoint() {
        #expect(RouteSpotType.fromGeneratedType("intermediate") == .waypoint)
    }

    @Test func fromGeneratedType_destination_returnsDestination() {
        #expect(RouteSpotType.fromGeneratedType("destination") == .destination)
    }

    @Test func fromGeneratedType_unknownValue_returnsWaypoint() {
        #expect(RouteSpotType.fromGeneratedType("unknown") == .waypoint)
    }

    @Test func fromGeneratedType_emptyString_returnsWaypoint() {
        #expect(RouteSpotType.fromGeneratedType("") == .waypoint)
    }

    @Test func fromGeneratedType_caseInsensitiveStart_returnsWaypoint() {
        #expect(RouteSpotType.fromGeneratedType("START") == .waypoint)
    }

    // MARK: - Codable Tests

    @Test func encode_start_producesCorrectJSON() throws {
        let data = try JSONEncoder().encode(RouteSpotType.start)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "\"start\"")
    }

    @Test func decode_start_fromJSON() throws {
        let json = "\"start\""
        let data = json.data(using: .utf8)!
        let type = try JSONDecoder().decode(RouteSpotType.self, from: data)
        #expect(type == .start)
    }

    @Test func decode_waypoint_fromJSON() throws {
        let json = "\"waypoint\""
        let data = json.data(using: .utf8)!
        let type = try JSONDecoder().decode(RouteSpotType.self, from: data)
        #expect(type == .waypoint)
    }

    @Test func decode_destination_fromJSON() throws {
        let json = "\"destination\""
        let data = json.data(using: .utf8)!
        let type = try JSONDecoder().decode(RouteSpotType.self, from: data)
        #expect(type == .destination)
    }
}

struct RouteSpotTests {
    // MARK: - Initialization Tests

    @Test func init_setsPropertiesCorrectly() {
        let spot = RouteSpot(
            name: "東京駅",
            type: .start,
            description: "出発地点",
            point: "35.6812,139.7671"
        )
        #expect(spot.name == "東京駅")
        #expect(spot.type == .start)
        #expect(spot.description == "出発地点")
        #expect(spot.point == "35.6812,139.7671")
    }

    @Test func init_withNilOptionals_works() {
        let spot = RouteSpot(
            name: "テストスポット",
            type: .waypoint,
            description: nil,
            point: nil
        )
        #expect(spot.name == "テストスポット")
        #expect(spot.type == .waypoint)
        #expect(spot.description == nil)
        #expect(spot.point == nil)
    }

    // MARK: - Identifiable Tests

    @Test func id_combinesNameTypeAndPoint() {
        let spot = RouteSpot(
            name: "東京駅",
            type: .start,
            description: nil,
            point: "point1"
        )
        #expect(spot.id == "東京駅startpoint1")
    }

    @Test func id_withNilPoint_combinesNameAndType() {
        let spot = RouteSpot(
            name: "東京駅",
            type: .start,
            description: nil,
            point: nil
        )
        #expect(spot.id == "東京駅start")
    }

    // MARK: - Equatable Tests

    @Test func equals_withSameValues_returnsTrue() {
        let spot1 = RouteSpot(name: "A", type: .start, description: "desc", point: "p1")
        let spot2 = RouteSpot(name: "A", type: .start, description: "desc", point: "p1")
        #expect(spot1 == spot2)
    }

    @Test func equals_withDifferentName_returnsFalse() {
        let spot1 = RouteSpot(name: "A", type: .start, description: nil, point: nil)
        let spot2 = RouteSpot(name: "B", type: .start, description: nil, point: nil)
        #expect(spot1 != spot2)
    }

    @Test func equals_withDifferentType_returnsFalse() {
        let spot1 = RouteSpot(name: "A", type: .start, description: nil, point: nil)
        let spot2 = RouteSpot(name: "A", type: .destination, description: nil, point: nil)
        #expect(spot1 != spot2)
    }
}
