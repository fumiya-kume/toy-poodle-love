import CoreLocation
import Foundation
import MapKit
import Testing
@testable import handheld

// MARK: - PlanRouteService Tests

struct PlanRouteServiceTests {
    // MARK: - calculateTotalMetrics Tests

    @Test func calculateTotalMetrics_emptyRoutes_returnsTotalStayDurationOnly() async {
        let service = PlanRouteService()
        let routes: [SpotRoute] = []
        let spots = [
            TestFactory.createMockPlanSpot(stayDuration: 30 * 60),
            TestFactory.createMockPlanSpot(stayDuration: 60 * 60)
        ]

        let metrics = service.calculateTotalMetrics(from: routes, spots: spots)

        #expect(metrics.totalDistance == 0)
        #expect(metrics.totalDuration == 90 * 60)
    }

    @Test func calculateTotalMetrics_emptySpots_returnsTotalRouteOnly() async {
        let directionsService = MockPlanRouteDirectionsService()
        let routeService = PlanRouteService(directionsService: directionsService)
        let spots: [PlanSpot] = []

        let metrics = routeService.calculateTotalMetrics(from: [], spots: spots)

        #expect(metrics.totalDistance == 0)
        #expect(metrics.totalDuration == 0)
    }

    @Test func calculateTotalMetrics_bothEmpty_returnsZeros() async {
        let service = PlanRouteService()
        let routes: [SpotRoute] = []
        let spots: [PlanSpot] = []

        let metrics = service.calculateTotalMetrics(from: routes, spots: spots)

        #expect(metrics.totalDistance == 0)
        #expect(metrics.totalDuration == 0)
    }
}

// MARK: - RouteCalculationResult Tests

struct RouteCalculationResultTests {
    @Test func hasPartialFailure_someFailures_returnsTrue() {
        let routes = [TestFactory.createMockSpotRoute()]
        let failures = [RouteFailure(
            fromSpotIndex: 1,
            toSpotIndex: 2,
            fromSpotName: "A",
            toSpotName: "B",
            error: NSError(domain: "Test", code: 0)
        )]
        let realRoutes = routes.map { mockRoute in
            createSpotRoute(from: mockRoute)
        }

        let result = RouteCalculationResult(routes: realRoutes, failures: failures)

        #expect(result.hasPartialFailure == true)
    }

    @Test func hasPartialFailure_noFailures_returnsFalse() {
        let routes = [TestFactory.createMockSpotRoute()]
        let realRoutes = routes.map { mockRoute in
            createSpotRoute(from: mockRoute)
        }

        let result = RouteCalculationResult(routes: realRoutes, failures: [])

        #expect(result.hasPartialFailure == false)
    }

    @Test func hasPartialFailure_noRoutesWithFailures_returnsFalse() {
        let failures = [RouteFailure(
            fromSpotIndex: 0,
            toSpotIndex: 1,
            fromSpotName: "A",
            toSpotName: "B",
            error: NSError(domain: "Test", code: 0)
        )]

        let result = RouteCalculationResult(routes: [], failures: failures)

        #expect(result.hasPartialFailure == false)
    }

    @Test func allSucceeded_noFailures_returnsTrue() {
        let routes = [TestFactory.createMockSpotRoute()]
        let realRoutes = routes.map { mockRoute in
            createSpotRoute(from: mockRoute)
        }

        let result = RouteCalculationResult(routes: realRoutes, failures: [])

        #expect(result.allSucceeded == true)
    }

    @Test func allSucceeded_withFailures_returnsFalse() {
        let routes = [TestFactory.createMockSpotRoute()]
        let failures = [RouteFailure(
            fromSpotIndex: 1,
            toSpotIndex: 2,
            fromSpotName: "A",
            toSpotName: "B",
            error: NSError(domain: "Test", code: 0)
        )]
        let realRoutes = routes.map { mockRoute in
            createSpotRoute(from: mockRoute)
        }

        let result = RouteCalculationResult(routes: realRoutes, failures: failures)

        #expect(result.allSucceeded == false)
    }
}

// MARK: - GeneratedPlan Tests

struct GeneratedPlanTests {
    @Test func init_setsCorrectValues() {
        let spots = [
            GeneratedSpotInfo(name: "スポット1", description: "説明1", stayMinutes: 30),
            GeneratedSpotInfo(name: "スポット2", description: "説明2", stayMinutes: 60)
        ]
        let plan = GeneratedPlan(title: "テストプラン", spots: spots)

        #expect(plan.title == "テストプラン")
        #expect(plan.spots.count == 2)
        #expect(plan.spots[0].name == "スポット1")
        #expect(plan.spots[1].name == "スポット2")
    }
}

// MARK: - GeneratedSpotInfo Tests

struct GeneratedSpotInfoTests {
    @Test func init_setsCorrectValues() {
        let spot = GeneratedSpotInfo(name: "東京駅", description: "歴史ある駅", stayMinutes: 30)

        #expect(spot.name == "東京駅")
        #expect(spot.description == "歴史ある駅")
        #expect(spot.stayMinutes == 30)
    }
}

// MARK: - Helper Functions

private func createSpotRoute(from mock: MockSpotRoute) -> SpotRoute {
    let coordinate1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    let coordinate2 = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
    let placemark1 = MKPlacemark(coordinate: coordinate1)
    let placemark2 = MKPlacemark(coordinate: coordinate2)
    let mapItem1 = MKMapItem(placemark: placemark1)
    let mapItem2 = MKMapItem(placemark: placemark2)

    let request = MKDirections.Request()
    request.source = mapItem1
    request.destination = mapItem2
    request.transportType = .automobile

    // 実際のルートが必要なため、モックのRouteを直接作成
    let points = [coordinate1, coordinate2]
    let polyline = MKPolyline(coordinates: points, count: points.count)

    let route = Route(
        polyline: polyline,
        distance: mock.distance,
        expectedTravelTime: mock.expectedTravelTime
    )

    return SpotRoute(
        fromSpotIndex: mock.fromSpotIndex,
        toSpotIndex: mock.toSpotIndex,
        route: route
    )
}

// MARK: - Mock DirectionsService for PlanRouteService Tests

final class MockPlanRouteDirectionsService: DirectionsServiceProtocol {
    var shouldFail = false
    var mockRoute: Route?

    func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> Route? {
        try await calculateRoute(from: source, to: destination, transportType: .walking)
    }

    func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: TransportType
    ) async throws -> Route? {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        return mockRoute
    }
}
