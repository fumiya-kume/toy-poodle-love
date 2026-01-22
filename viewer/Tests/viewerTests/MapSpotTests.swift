import XCTest
import MapKit
@testable import VideoOverlayViewer

final class MapSpotTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsAllPropertiesCorrectly() {
        let id = UUID()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot = MapSpot(
            id: id,
            name: "東京駅",
            coordinate: coordinate,
            type: .start,
            address: "〒100-0005 東京都千代田区丸の内１丁目",
            description: "東京の中心駅",
            order: 0
        )

        XCTAssertEqual(spot.id, id)
        XCTAssertEqual(spot.name, "東京駅")
        XCTAssertEqual(spot.coordinate.latitude, 35.6812, accuracy: 0.0001)
        XCTAssertEqual(spot.coordinate.longitude, 139.7671, accuracy: 0.0001)
        XCTAssertEqual(spot.type, .start)
        XCTAssertEqual(spot.address, "〒100-0005 東京都千代田区丸の内１丁目")
        XCTAssertEqual(spot.description, "東京の中心駅")
        XCTAssertEqual(spot.order, 0)
    }

    func testInit_withDefaultId_generatesUUID() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot = MapSpot(
            name: "新宿駅",
            coordinate: coordinate,
            type: .waypoint,
            address: nil,
            description: nil,
            order: 1
        )

        XCTAssertNotNil(spot.id)
    }

    func testInit_withNilOptionalValues_setsNil() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot = MapSpot(
            name: "渋谷駅",
            coordinate: coordinate,
            type: .destination,
            address: nil,
            description: nil,
            order: 2
        )

        XCTAssertNil(spot.address)
        XCTAssertNil(spot.description)
    }

    // MARK: - MapSpotType Tests

    func testMapSpotType_start() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let spot = MapSpot(
            name: "Start",
            coordinate: coordinate,
            type: .start,
            address: nil,
            description: nil,
            order: 0
        )

        XCTAssertEqual(spot.type, .start)
    }

    func testMapSpotType_waypoint() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let spot = MapSpot(
            name: "Waypoint",
            coordinate: coordinate,
            type: .waypoint,
            address: nil,
            description: nil,
            order: 1
        )

        XCTAssertEqual(spot.type, .waypoint)
    }

    func testMapSpotType_destination() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let spot = MapSpot(
            name: "Destination",
            coordinate: coordinate,
            type: .destination,
            address: nil,
            description: nil,
            order: 2
        )

        XCTAssertEqual(spot.type, .destination)
    }

    // MARK: - Equatable Tests

    func testEquatable_sameId_returnsTrue() {
        let id = UUID()
        let coordinate1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let coordinate2 = CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5022)

        let spot1 = MapSpot(
            id: id,
            name: "Spot 1",
            coordinate: coordinate1,
            type: .start,
            address: "Address 1",
            description: "Description 1",
            order: 0
        )

        let spot2 = MapSpot(
            id: id,
            name: "Spot 2",
            coordinate: coordinate2,
            type: .destination,
            address: "Address 2",
            description: "Description 2",
            order: 1
        )

        XCTAssertEqual(spot1, spot2)
    }

    func testEquatable_differentId_returnsFalse() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot1 = MapSpot(
            id: UUID(),
            name: "Spot",
            coordinate: coordinate,
            type: .start,
            address: "Address",
            description: "Description",
            order: 0
        )

        let spot2 = MapSpot(
            id: UUID(),
            name: "Spot",
            coordinate: coordinate,
            type: .start,
            address: "Address",
            description: "Description",
            order: 0
        )

        XCTAssertNotEqual(spot1, spot2)
    }

    // MARK: - Hashable Tests

    func testHashable_sameId_hasSameHashValue() {
        let id = UUID()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot1 = MapSpot(
            id: id,
            name: "Spot 1",
            coordinate: coordinate,
            type: .start,
            address: nil,
            description: nil,
            order: 0
        )

        let spot2 = MapSpot(
            id: id,
            name: "Spot 2",
            coordinate: coordinate,
            type: .destination,
            address: nil,
            description: nil,
            order: 1
        )

        XCTAssertEqual(spot1.hashValue, spot2.hashValue)
    }

    func testHashable_canBeUsedInSet() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot1 = MapSpot(
            id: UUID(),
            name: "Spot 1",
            coordinate: coordinate,
            type: .start,
            address: nil,
            description: nil,
            order: 0
        )

        let spot2 = MapSpot(
            id: UUID(),
            name: "Spot 2",
            coordinate: coordinate,
            type: .waypoint,
            address: nil,
            description: nil,
            order: 1
        )

        var spotSet = Set<MapSpot>()
        spotSet.insert(spot1)
        spotSet.insert(spot2)

        XCTAssertEqual(spotSet.count, 2)
        XCTAssertTrue(spotSet.contains(spot1))
        XCTAssertTrue(spotSet.contains(spot2))
    }

    func testHashable_duplicateId_onlyOneInSet() {
        let id = UUID()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot1 = MapSpot(
            id: id,
            name: "Spot 1",
            coordinate: coordinate,
            type: .start,
            address: nil,
            description: nil,
            order: 0
        )

        let spot2 = MapSpot(
            id: id,
            name: "Spot 2",
            coordinate: coordinate,
            type: .destination,
            address: nil,
            description: nil,
            order: 1
        )

        var spotSet = Set<MapSpot>()
        spotSet.insert(spot1)
        spotSet.insert(spot2)

        XCTAssertEqual(spotSet.count, 1)
    }

    // MARK: - Identifiable Tests

    func testIdentifiable_idProperty_returnsUUID() {
        let uuid = UUID()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        let spot = MapSpot(
            id: uuid,
            name: "Test Spot",
            coordinate: coordinate,
            type: .waypoint,
            address: nil,
            description: nil,
            order: 0
        )

        XCTAssertEqual(spot.id, uuid)
    }

    // MARK: - Order Tests

    func testOrder_sortingByOrder() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let spot1 = MapSpot(name: "Third", coordinate: coordinate, type: .destination, address: nil, description: nil, order: 2)
        let spot2 = MapSpot(name: "First", coordinate: coordinate, type: .start, address: nil, description: nil, order: 0)
        let spot3 = MapSpot(name: "Second", coordinate: coordinate, type: .waypoint, address: nil, description: nil, order: 1)

        let spots = [spot1, spot2, spot3].sorted { $0.order < $1.order }

        XCTAssertEqual(spots[0].name, "First")
        XCTAssertEqual(spots[1].name, "Second")
        XCTAssertEqual(spots[2].name, "Third")
    }
}

// MARK: - MapSpotType Tests

final class MapSpotTypeTests: XCTestCase {

    func testHashable_conformance() {
        let types: [MapSpot.MapSpotType] = [.start, .waypoint, .destination]
        var typeSet = Set<MapSpot.MapSpotType>()

        for type in types {
            typeSet.insert(type)
        }

        XCTAssertEqual(typeSet.count, 3)
    }

    func testHashable_sameTypesHaveSameHash() {
        let type1 = MapSpot.MapSpotType.start
        let type2 = MapSpot.MapSpotType.start

        XCTAssertEqual(type1.hashValue, type2.hashValue)
    }

    func testEquatable_sameTypes_areEqual() {
        XCTAssertEqual(MapSpot.MapSpotType.start, MapSpot.MapSpotType.start)
        XCTAssertEqual(MapSpot.MapSpotType.waypoint, MapSpot.MapSpotType.waypoint)
        XCTAssertEqual(MapSpot.MapSpotType.destination, MapSpot.MapSpotType.destination)
    }

    func testEquatable_differentTypes_areNotEqual() {
        XCTAssertNotEqual(MapSpot.MapSpotType.start, MapSpot.MapSpotType.waypoint)
        XCTAssertNotEqual(MapSpot.MapSpotType.waypoint, MapSpot.MapSpotType.destination)
        XCTAssertNotEqual(MapSpot.MapSpotType.start, MapSpot.MapSpotType.destination)
    }
}
