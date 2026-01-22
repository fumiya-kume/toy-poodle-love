import XCTest
@testable import VideoOverlayViewer

// MARK: - LatLng Tests

final class LatLngTests: XCTestCase {

    func testInit_setsPropertiesCorrectly() {
        let latLng = LatLng(latitude: 35.6812, longitude: 139.7671)

        XCTAssertEqual(latLng.latitude, 35.6812)
        XCTAssertEqual(latLng.longitude, 139.7671)
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = LatLng(latitude: 35.6812, longitude: 139.7671)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(LatLng.self, from: data)

        XCTAssertEqual(decoded.latitude, original.latitude)
        XCTAssertEqual(decoded.longitude, original.longitude)
    }

    func testEquatable_sameValues_returnsTrue() {
        let latLng1 = LatLng(latitude: 35.6812, longitude: 139.7671)
        let latLng2 = LatLng(latitude: 35.6812, longitude: 139.7671)

        XCTAssertEqual(latLng1, latLng2)
    }

    func testEquatable_differentValues_returnsFalse() {
        let latLng1 = LatLng(latitude: 35.6812, longitude: 139.7671)
        let latLng2 = LatLng(latitude: 34.6937, longitude: 135.5022)

        XCTAssertNotEqual(latLng1, latLng2)
    }

    func testCodable_fromJSON_decodesCorrectly() throws {
        let json = """
        {
            "latitude": 35.6812,
            "longitude": 139.7671
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(LatLng.self, from: json)

        XCTAssertEqual(decoded.latitude, 35.6812, accuracy: 0.0001)
        XCTAssertEqual(decoded.longitude, 139.7671, accuracy: 0.0001)
    }
}

// MARK: - TextGenerationRequest Tests

final class TextGenerationRequestTests: XCTestCase {

    func testInit_setsMessageCorrectly() {
        let request = TextGenerationRequest(message: "Hello, World!")
        XCTAssertEqual(request.message, "Hello, World!")
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = TextGenerationRequest(message: "Test message")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TextGenerationRequest.self, from: data)

        XCTAssertEqual(decoded.message, original.message)
    }

    func testCodable_toJSON_hasCorrectFormat() throws {
        let request = TextGenerationRequest(message: "Test")

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["message"] as? String, "Test")
    }
}

// MARK: - TextGenerationResponse Tests

final class TextGenerationResponseTests: XCTestCase {

    func testInit_setsResponseCorrectly() {
        let response = TextGenerationResponse(response: "Generated text")
        XCTAssertEqual(response.response, "Generated text")
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = TextGenerationResponse(response: "Test response")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TextGenerationResponse.self, from: data)

        XCTAssertEqual(decoded.response, original.response)
    }

    func testCodable_fromJSON_decodesCorrectly() throws {
        let json = """
        {
            "response": "AI generated text"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(TextGenerationResponse.self, from: json)

        XCTAssertEqual(decoded.response, "AI generated text")
    }
}

// MARK: - GeocodeRequest Tests

final class GeocodeRequestTests: XCTestCase {

    func testInit_setsAddressesCorrectly() {
        let request = GeocodeRequest(addresses: ["東京駅", "新宿駅"])

        XCTAssertEqual(request.addresses.count, 2)
        XCTAssertEqual(request.addresses[0], "東京駅")
        XCTAssertEqual(request.addresses[1], "新宿駅")
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = GeocodeRequest(addresses: ["Address 1", "Address 2"])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GeocodeRequest.self, from: data)

        XCTAssertEqual(decoded.addresses, original.addresses)
    }

    func testInit_emptyAddresses() {
        let request = GeocodeRequest(addresses: [])
        XCTAssertTrue(request.addresses.isEmpty)
    }
}

// MARK: - GeocodeResponse Tests

final class GeocodeResponseTests: XCTestCase {

    func testInit_setsPropertiesCorrectly() {
        let places = [
            GeocodedPlace(
                inputAddress: "東京駅",
                location: LatLng(latitude: 35.6812, longitude: 139.7671),
                formattedAddress: "〒100-0005 東京都千代田区丸の内１丁目",
                placeId: "ChIJC3Cf2PuLGGARO2ZYV3dpHQQ"
            )
        ]
        let response = GeocodeResponse(success: true, places: places)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.places.count, 1)
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let places = [
            GeocodedPlace(
                inputAddress: "Test",
                location: LatLng(latitude: 35.0, longitude: 139.0),
                formattedAddress: "Formatted",
                placeId: "abc123"
            )
        ]
        let original = GeocodeResponse(success: true, places: places)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GeocodeResponse.self, from: data)

        XCTAssertEqual(decoded.success, original.success)
        XCTAssertEqual(decoded.places.count, original.places.count)
    }
}

// MARK: - GeocodedPlace Tests

final class GeocodedPlaceTests: XCTestCase {

    func testInit_setsPropertiesCorrectly() {
        let place = GeocodedPlace(
            inputAddress: "東京駅",
            location: LatLng(latitude: 35.6812, longitude: 139.7671),
            formattedAddress: "〒100-0005 東京都千代田区丸の内１丁目",
            placeId: "ChIJC3Cf2PuLGGARO2ZYV3dpHQQ"
        )

        XCTAssertEqual(place.inputAddress, "東京駅")
        XCTAssertEqual(place.location.latitude, 35.6812)
        XCTAssertEqual(place.formattedAddress, "〒100-0005 東京都千代田区丸の内１丁目")
        XCTAssertEqual(place.placeId, "ChIJC3Cf2PuLGGARO2ZYV3dpHQQ")
    }

    func testIdentifiable_idReturnsPlaceId() {
        let place = GeocodedPlace(
            inputAddress: "Test",
            location: LatLng(latitude: 0, longitude: 0),
            formattedAddress: "Test",
            placeId: "uniqueId123"
        )

        XCTAssertEqual(place.id, "uniqueId123")
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = GeocodedPlace(
            inputAddress: "Test",
            location: LatLng(latitude: 35.0, longitude: 139.0),
            formattedAddress: "Formatted Address",
            placeId: "placeId123"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GeocodedPlace.self, from: data)

        XCTAssertEqual(decoded.inputAddress, original.inputAddress)
        XCTAssertEqual(decoded.location, original.location)
        XCTAssertEqual(decoded.formattedAddress, original.formattedAddress)
        XCTAssertEqual(decoded.placeId, original.placeId)
    }
}

// MARK: - RouteWaypoint Tests

final class RouteWaypointTests: XCTestCase {

    func testInit_withAllParameters() {
        let location = LatLng(latitude: 35.6812, longitude: 139.7671)
        let waypoint = RouteWaypoint(
            name: "東京駅",
            placeId: "ChIJC3Cf2PuLGGARO2ZYV3dpHQQ",
            address: "〒100-0005 東京都千代田区丸の内１丁目",
            location: location
        )

        XCTAssertEqual(waypoint.name, "東京駅")
        XCTAssertEqual(waypoint.placeId, "ChIJC3Cf2PuLGGARO2ZYV3dpHQQ")
        XCTAssertEqual(waypoint.address, "〒100-0005 東京都千代田区丸の内１丁目")
        XCTAssertEqual(waypoint.location, location)
    }

    func testInit_withDefaultValues() {
        let waypoint = RouteWaypoint()

        XCTAssertNil(waypoint.name)
        XCTAssertNil(waypoint.placeId)
        XCTAssertNil(waypoint.address)
        XCTAssertNil(waypoint.location)
    }

    func testIdentifiable_id_prefersPlaceId() {
        let waypoint = RouteWaypoint(
            name: "Name",
            placeId: "placeId123",
            address: "Address"
        )

        XCTAssertEqual(waypoint.id, "placeId123")
    }

    func testIdentifiable_id_fallsBackToAddress() {
        let waypoint = RouteWaypoint(
            name: "Name",
            address: "Address123"
        )

        XCTAssertEqual(waypoint.id, "Address123")
    }

    func testIdentifiable_id_fallsBackToName() {
        let waypoint = RouteWaypoint(name: "NameOnly")

        XCTAssertEqual(waypoint.id, "NameOnly")
    }

    func testEquatable_sameProperties_returnsTrue() {
        let location = LatLng(latitude: 35.0, longitude: 139.0)
        let waypoint1 = RouteWaypoint(name: "Test", placeId: "id", address: "addr", location: location)
        let waypoint2 = RouteWaypoint(name: "Test", placeId: "id", address: "addr", location: location)

        XCTAssertEqual(waypoint1, waypoint2)
    }

    func testEquatable_differentProperties_returnsFalse() {
        let waypoint1 = RouteWaypoint(name: "Test1")
        let waypoint2 = RouteWaypoint(name: "Test2")

        XCTAssertNotEqual(waypoint1, waypoint2)
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = RouteWaypoint(
            name: "Test",
            placeId: "id123",
            address: "Address",
            location: LatLng(latitude: 35.0, longitude: 139.0)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RouteWaypoint.self, from: data)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.placeId, original.placeId)
        XCTAssertEqual(decoded.address, original.address)
        XCTAssertEqual(decoded.location, original.location)
    }
}

// MARK: - TravelMode Tests

final class TravelModeTests: XCTestCase {

    func testRawValue_driving() {
        XCTAssertEqual(TravelMode.driving.rawValue, "DRIVE")
    }

    func testRawValue_walking() {
        XCTAssertEqual(TravelMode.walking.rawValue, "WALK")
    }

    func testRawValue_bicycling() {
        XCTAssertEqual(TravelMode.bicycling.rawValue, "BICYCLE")
    }

    func testRawValue_transit() {
        XCTAssertEqual(TravelMode.transit.rawValue, "TRANSIT")
    }

    func testDisplayName_driving() {
        XCTAssertEqual(TravelMode.driving.displayName, "車")
    }

    func testDisplayName_walking() {
        XCTAssertEqual(TravelMode.walking.displayName, "徒歩")
    }

    func testDisplayName_bicycling() {
        XCTAssertEqual(TravelMode.bicycling.displayName, "自転車")
    }

    func testDisplayName_transit() {
        XCTAssertEqual(TravelMode.transit.displayName, "公共交通機関")
    }

    func testIdentifiable_id_returnsRawValue() {
        XCTAssertEqual(TravelMode.driving.id, "DRIVE")
    }

    func testCaseIterable_allCases() {
        XCTAssertEqual(TravelMode.allCases.count, 4)
        XCTAssertTrue(TravelMode.allCases.contains(.driving))
        XCTAssertTrue(TravelMode.allCases.contains(.walking))
        XCTAssertTrue(TravelMode.allCases.contains(.bicycling))
        XCTAssertTrue(TravelMode.allCases.contains(.transit))
    }

    func testCodable_encodeAndDecode() throws {
        let original = TravelMode.driving

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TravelMode.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}

// MARK: - AIModel Tests

final class AIModelTests: XCTestCase {

    func testRawValue_gemini() {
        XCTAssertEqual(AIModel.gemini.rawValue, "gemini")
    }

    func testRawValue_qwen() {
        XCTAssertEqual(AIModel.qwen.rawValue, "qwen")
    }

    func testDisplayName_gemini() {
        XCTAssertEqual(AIModel.gemini.displayName, "Gemini")
    }

    func testDisplayName_qwen() {
        XCTAssertEqual(AIModel.qwen.displayName, "Qwen")
    }

    func testIdentifiable_id_returnsRawValue() {
        XCTAssertEqual(AIModel.gemini.id, "gemini")
        XCTAssertEqual(AIModel.qwen.id, "qwen")
    }

    func testCaseIterable_allCases() {
        XCTAssertEqual(AIModel.allCases.count, 2)
        XCTAssertTrue(AIModel.allCases.contains(.gemini))
        XCTAssertTrue(AIModel.allCases.contains(.qwen))
    }

    func testCodable_encodeAndDecode() throws {
        for model in AIModel.allCases {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model)
        }
    }

    func testToScenarioModels_gemini() {
        XCTAssertEqual(AIModel.gemini.toScenarioModels(), .gemini)
    }

    func testToScenarioModels_qwen() {
        XCTAssertEqual(AIModel.qwen.toScenarioModels(), .qwen)
    }
}

// MARK: - RouteOptimizeRequest Tests

final class RouteOptimizeRequestTests: XCTestCase {

    func testInit_withDefaultValues() {
        let origin = RouteWaypoint(name: "Origin")
        let destination = RouteWaypoint(name: "Destination")

        let request = RouteOptimizeRequest(origin: origin, destination: destination)

        XCTAssertEqual(request.origin.name, "Origin")
        XCTAssertEqual(request.destination.name, "Destination")
        XCTAssertTrue(request.intermediates.isEmpty)
        XCTAssertEqual(request.travelMode, .driving)
        XCTAssertTrue(request.optimizeWaypointOrder)
    }

    func testInit_withAllParameters() {
        let origin = RouteWaypoint(name: "Origin")
        let destination = RouteWaypoint(name: "Destination")
        let intermediates = [RouteWaypoint(name: "Stop 1")]

        let request = RouteOptimizeRequest(
            origin: origin,
            destination: destination,
            intermediates: intermediates,
            travelMode: .walking,
            optimizeWaypointOrder: false
        )

        XCTAssertEqual(request.intermediates.count, 1)
        XCTAssertEqual(request.travelMode, .walking)
        XCTAssertFalse(request.optimizeWaypointOrder)
    }

    func testCodable_encodeAndDecode_preservesData() throws {
        let original = RouteOptimizeRequest(
            origin: RouteWaypoint(name: "A"),
            destination: RouteWaypoint(name: "B"),
            intermediates: [RouteWaypoint(name: "C")],
            travelMode: .bicycling,
            optimizeWaypointOrder: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RouteOptimizeRequest.self, from: data)

        XCTAssertEqual(decoded.origin.name, original.origin.name)
        XCTAssertEqual(decoded.destination.name, original.destination.name)
        XCTAssertEqual(decoded.intermediates.count, original.intermediates.count)
        XCTAssertEqual(decoded.travelMode, original.travelMode)
        XCTAssertEqual(decoded.optimizeWaypointOrder, original.optimizeWaypointOrder)
    }
}

// MARK: - RouteOptimizeResponse Tests

final class RouteOptimizeResponseTests: XCTestCase {

    func testCodable_fromJSON_decodesCorrectly() throws {
        let json = """
        {
            "success": true,
            "optimizedRoute": {
                "orderedWaypoints": [],
                "legs": [],
                "totalDistanceMeters": 5000,
                "totalDurationSeconds": 600
            }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RouteOptimizeResponse.self, from: json)

        XCTAssertTrue(decoded.success)
        XCTAssertEqual(decoded.optimizedRoute.totalDistanceMeters, 5000)
        XCTAssertEqual(decoded.optimizedRoute.totalDurationSeconds, 600)
    }
}

// MARK: - OptimizedRoute Tests

final class OptimizedRouteTests: XCTestCase {

    func testCodable_fromJSON_decodesCorrectly() throws {
        let json = """
        {
            "orderedWaypoints": [
                {
                    "waypoint": {
                        "name": "Test"
                    },
                    "waypointIndex": 0
                }
            ],
            "legs": [
                {
                    "startLocation": {"latitude": 35.0, "longitude": 139.0},
                    "endLocation": {"latitude": 35.1, "longitude": 139.1},
                    "distanceMeters": 1000,
                    "durationSeconds": 120
                }
            ],
            "totalDistanceMeters": 1000,
            "totalDurationSeconds": 120
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OptimizedRoute.self, from: json)

        XCTAssertEqual(decoded.orderedWaypoints.count, 1)
        XCTAssertEqual(decoded.legs.count, 1)
        XCTAssertEqual(decoded.totalDistanceMeters, 1000)
        XCTAssertEqual(decoded.totalDurationSeconds, 120)
    }
}

// MARK: - OptimizedWaypoint Tests

final class OptimizedWaypointTests: XCTestCase {

    func testIdentifiable_id_returnsWaypointIndex() {
        let waypoint = RouteWaypoint(name: "Test")
        let optimizedWaypoint = OptimizedWaypoint(waypoint: waypoint, waypointIndex: 5)

        XCTAssertEqual(optimizedWaypoint.id, 5)
    }
}

// MARK: - RouteLeg Tests

final class RouteLegTests: XCTestCase {

    func testCodable_fromJSON_withAllFields() throws {
        let json = """
        {
            "startLocation": {"latitude": 35.0, "longitude": 139.0},
            "endLocation": {"latitude": 35.1, "longitude": 139.1},
            "distanceMeters": 1500,
            "durationSeconds": 180
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RouteLeg.self, from: json)

        XCTAssertNotNil(decoded.startLocation)
        XCTAssertNotNil(decoded.endLocation)
        XCTAssertEqual(decoded.distanceMeters, 1500)
        XCTAssertEqual(decoded.durationSeconds, 180)
    }

    func testCodable_fromJSON_withNullLocations() throws {
        let json = """
        {
            "startLocation": null,
            "endLocation": null,
            "distanceMeters": 1000,
            "durationSeconds": 120
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RouteLeg.self, from: json)

        XCTAssertNil(decoded.startLocation)
        XCTAssertNil(decoded.endLocation)
        XCTAssertEqual(decoded.distanceMeters, 1000)
        XCTAssertEqual(decoded.durationSeconds, 120)
    }
}
