import Testing
import MapKit
@testable import handheld

struct MockLocationSearchService: LocationSearchServiceProtocol {
    var mockResults: [Place] = []
    var shouldThrowError: Bool = false

    func search(query: String, region: MKCoordinateRegion?) async throws -> [Place] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockResults
    }
}

struct MockDirectionsService: DirectionsServiceProtocol {
    var mockRoute: Route?
    var shouldThrowError: Bool = false

    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Route? {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockRoute
    }

    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: TransportType) async throws -> Route? {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockRoute
    }
}

struct LocationSearchViewModelTests {
    @Test func initialState() {
        let viewModel = LocationSearchViewModel()
        #expect(viewModel.searchQuery == "")
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.selectedPlace == nil)
        #expect(viewModel.route == nil)
        #expect(viewModel.isSearching == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func searchWithEmptyQuery() async {
        let viewModel = LocationSearchViewModel()
        viewModel.searchQuery = "   "
        await viewModel.search()
        #expect(viewModel.searchResults.isEmpty)
    }

    @Test @MainActor func searchWithResults() async {
        var mockSearchService = MockSearchService()
        let mockPlace = createMockPlace(name: "東京駅")
        mockSearchService.mockResults = [mockPlace]

        let viewModel = LocationSearchViewModel(
            searchService: mockSearchService,
            directionsService: MockDirectionsService()
        )
        viewModel.searchQuery = "東京駅"
        await viewModel.search()

        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.searchResults.first?.name == "東京駅")
        #expect(viewModel.isSearching == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test @MainActor func searchWithError() async {
        var mockSearchService = MockSearchService()
        mockSearchService.shouldThrowError = true

        let viewModel = LocationSearchViewModel(
            searchService: mockSearchService,
            directionsService: MockDirectionsService()
        )
        viewModel.searchQuery = "東京"
        await viewModel.search()

        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSearching == false)
    }

    @Test func clearSearch() {
        let viewModel = LocationSearchViewModel()
        viewModel.searchQuery = "東京"
        viewModel.clearSearch()

        #expect(viewModel.searchQuery == "")
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.selectedPlace == nil)
        #expect(viewModel.route == nil)
        #expect(viewModel.errorMessage == nil)
    }

    private func createMockPlace(name: String) -> Place {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return Place(mapItem: mapItem)
    }
}

private struct MockSearchService: LocationSearchServiceProtocol {
    var mockResults: [Place] = []
    var shouldThrowError: Bool = false

    func search(query: String, region: MKCoordinateRegion?) async throws -> [Place] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockResults
    }
}

// MARK: - Look Around Tests

struct MockLookAroundService: LookAroundServiceProtocol {
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

struct LookAroundViewModelTests {
    @Test func initialLookAroundState() {
        let viewModel = LocationSearchViewModel()
        #expect(viewModel.destinationLookAroundScene == nil)
        #expect(viewModel.nextStepLookAroundScene == nil)
        #expect(viewModel.isLoadingLookAround == false)
        #expect(viewModel.showLookAround == false)
        #expect(viewModel.showLookAroundSheet == false)
        #expect(viewModel.lookAroundTarget == .destination)
    }

    @Test func hasLookAroundAvailableWhenNoScenes() {
        let viewModel = LocationSearchViewModel()
        #expect(viewModel.hasLookAroundAvailable == false)
    }

    @Test func dismissLookAround() {
        let viewModel = LocationSearchViewModel()
        viewModel.showLookAround = true
        viewModel.dismissLookAround()
        #expect(viewModel.showLookAround == false)
    }

    @Test func openLookAroundSheet() {
        let viewModel = LocationSearchViewModel()
        viewModel.openLookAroundSheet()
        #expect(viewModel.showLookAroundSheet == true)
    }

    @Test func showLookAroundCardWhenNotAvailable() {
        let viewModel = LocationSearchViewModel()
        viewModel.showLookAroundCard()
        #expect(viewModel.showLookAround == false)
    }

    @Test func lookAroundLocationNameForDestination() {
        let viewModel = LocationSearchViewModel()
        viewModel.lookAroundTarget = .destination
        #expect(viewModel.lookAroundLocationName == "目的地")
    }

    @Test func lookAroundLocationNameForNextStep() {
        let viewModel = LocationSearchViewModel()
        viewModel.lookAroundTarget = .nextStep
        #expect(viewModel.lookAroundLocationName == "次の曲がり角")
    }

    @Test func hasNextStepWhenNoRoute() {
        let viewModel = LocationSearchViewModel()
        #expect(viewModel.hasNextStep == false)
    }
}
