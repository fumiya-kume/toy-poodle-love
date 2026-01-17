import CoreLocation
import MapKit
import Testing
@testable import handheld

// MARK: - Mock LookAroundService

struct MockLookAroundServiceForAutoDrive: LookAroundServiceProtocol {
    var mockScene: MKLookAroundScene?
    var shouldThrowError: Bool = false

    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockScene
    }

    func fetchScenesProgressively(
        for steps: [NavigationStep],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async {
        for (index, _) in steps.enumerated() {
            await onSceneFetched(index, mockScene)
        }
    }
}

// MARK: - Tests

struct AutoDriveServiceTests {
    // MARK: - extractDrivePoints

    @Test func extractDrivePoints_emptyPolyline_returnsEmpty() {
        let service = AutoDriveService()
        let coordinates: [CLLocationCoordinate2D] = []
        let polyline = MKPolyline(coordinates: coordinates, count: 0)

        let points = service.extractDrivePoints(from: polyline)

        #expect(points.isEmpty)
    }

    @Test func extractDrivePoints_singlePoint_returnsSinglePoint() {
        let service = AutoDriveService()
        var coordinates = [CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)]
        let polyline = MKPolyline(coordinates: &coordinates, count: 1)

        let points = service.extractDrivePoints(from: polyline)

        #expect(points.count == 1)
        #expect(abs(points[0].coordinate.latitude - 35.6812) < 0.0001)
        #expect(abs(points[0].coordinate.longitude - 139.7671) < 0.0001)
    }

    @Test func extractDrivePoints_twoClosePoints_includesStartAndEnd() {
        let service = AutoDriveService()
        // Two points less than 30m apart
        var coordinates = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.68121, longitude: 139.76711)
        ]
        let polyline = MKPolyline(coordinates: &coordinates, count: 2)

        let points = service.extractDrivePoints(from: polyline)

        #expect(points.count >= 1) // At least start point
        #expect(points.first?.coordinate.latitude == 35.6812)
    }

    @Test func extractDrivePoints_longRoute_extractsAtIntervals() {
        let service = AutoDriveService()
        // Create a route of about 100m (each point ~10m apart)
        var coordinates: [CLLocationCoordinate2D] = []
        let startLat = 35.6812
        let startLon = 139.7671
        // About 10m per 0.0001 degrees latitude
        for i in 0..<15 {
            coordinates.append(CLLocationCoordinate2D(
                latitude: startLat + Double(i) * 0.0003, // ~30m apart
                longitude: startLon
            ))
        }
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)

        let points = service.extractDrivePoints(from: polyline, interval: 30)

        // Should have multiple points extracted
        #expect(points.count >= 2)
        // First point should be start
        #expect(points.first?.index == 0)
    }

    @Test func extractDrivePoints_ensuresEndPointIncluded() {
        let service = AutoDriveService()
        // Create a route where end point would not naturally land on interval
        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<10 {
            coordinates.append(CLLocationCoordinate2D(
                latitude: 35.6812 + Double(i) * 0.0002,
                longitude: 139.7671
            ))
        }
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)

        let points = service.extractDrivePoints(from: polyline, interval: 30)

        // Last point should be the route end
        if let lastPoint = points.last {
            let endCoord = coordinates.last!
            #expect(abs(lastPoint.coordinate.latitude - endCoord.latitude) < 0.0001)
            #expect(abs(lastPoint.coordinate.longitude - endCoord.longitude) < 0.0001)
        }
    }

    @Test func extractDrivePoints_indicesAreSequential() {
        let service = AutoDriveService()
        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<20 {
            coordinates.append(CLLocationCoordinate2D(
                latitude: 35.6812 + Double(i) * 0.0003,
                longitude: 139.7671
            ))
        }
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)

        let points = service.extractDrivePoints(from: polyline, interval: 30)

        // Verify indices are sequential
        for (i, point) in points.enumerated() {
            #expect(point.index == i)
        }
    }

    @Test func extractDrivePoints_customInterval_respectsInterval() {
        let service = AutoDriveService()
        // Create a longer route
        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<30 {
            coordinates.append(CLLocationCoordinate2D(
                latitude: 35.6812 + Double(i) * 0.0005, // ~50m apart
                longitude: 139.7671
            ))
        }
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)

        let points30m = service.extractDrivePoints(from: polyline, interval: 30)
        let points100m = service.extractDrivePoints(from: polyline, interval: 100)

        // Larger interval should result in fewer points
        #expect(points30m.count >= points100m.count)
    }

    // MARK: - fetchInitialScenes

    @Test @MainActor func fetchInitialScenes_emptyPoints_returnsZero() async {
        let mockLookAroundService = MockLookAroundServiceForAutoDrive()
        let service = AutoDriveService(lookAroundService: mockLookAroundService)

        let points: [RouteCoordinatePoint] = []
        var callbackCount = 0

        let successCount = await service.fetchInitialScenes(
            for: points,
            initialCount: 3
        ) { _, _ in
            callbackCount += 1
        }

        #expect(successCount == 0)
        #expect(callbackCount == 0)
    }

    @Test @MainActor func fetchInitialScenes_withPoints_callsCallback() async {
        let mockLookAroundService = MockLookAroundServiceForAutoDrive(mockScene: nil)
        let service = AutoDriveService(lookAroundService: mockLookAroundService)

        let points = [
            RouteCoordinatePoint(index: 0, coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)),
            RouteCoordinatePoint(index: 1, coordinate: CLLocationCoordinate2D(latitude: 35.6813, longitude: 139.7672)),
            RouteCoordinatePoint(index: 2, coordinate: CLLocationCoordinate2D(latitude: 35.6814, longitude: 139.7673))
        ]
        var callbackCount = 0

        _ = await service.fetchInitialScenes(
            for: points,
            initialCount: 3
        ) { _, _ in
            callbackCount += 1
        }

        #expect(callbackCount == 3)
    }

    @Test @MainActor func fetchInitialScenes_respectsInitialCount() async {
        let mockLookAroundService = MockLookAroundServiceForAutoDrive(mockScene: nil)
        let service = AutoDriveService(lookAroundService: mockLookAroundService)

        let points = [
            RouteCoordinatePoint(index: 0, coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)),
            RouteCoordinatePoint(index: 1, coordinate: CLLocationCoordinate2D(latitude: 35.6813, longitude: 139.7672)),
            RouteCoordinatePoint(index: 2, coordinate: CLLocationCoordinate2D(latitude: 35.6814, longitude: 139.7673)),
            RouteCoordinatePoint(index: 3, coordinate: CLLocationCoordinate2D(latitude: 35.6815, longitude: 139.7674)),
            RouteCoordinatePoint(index: 4, coordinate: CLLocationCoordinate2D(latitude: 35.6816, longitude: 139.7675))
        ]
        var callbackCount = 0

        _ = await service.fetchInitialScenes(
            for: points,
            initialCount: 2
        ) { _, _ in
            callbackCount += 1
        }

        #expect(callbackCount == 2) // Only fetches initialCount items
    }
}

// MARK: - RouteCoordinatePoint Tests

struct RouteCoordinatePointTests {
    @Test func init_setsCorrectValues() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let point = RouteCoordinatePoint(index: 5, coordinate: coordinate)

        #expect(point.index == 5)
        #expect(point.coordinate.latitude == 35.6812)
        #expect(point.coordinate.longitude == 139.7671)
    }

    @Test func init_setsDefaultValues() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let point = RouteCoordinatePoint(index: 0, coordinate: coordinate)

        #expect(point.lookAroundScene == nil)
        #expect(point.isLookAroundLoading == true)
        #expect(point.lookAroundFetchFailed == false)
    }

    @Test func hasScene_whenSceneNil_returnsFalse() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let point = RouteCoordinatePoint(index: 0, coordinate: coordinate)

        #expect(point.hasScene == false)
    }
}
