import CoreLocation
import MapKit
import Testing
@testable import handheld

// MARK: - Mock Services

struct MockSpotSearchService: SpotSearchServiceProtocol {
    var mockPlaces: [Place] = []
    var shouldThrowError: Bool = false

    func searchSpots(
        theme: String,
        categories: [PlanCategory],
        centerCoordinate: CLLocationCoordinate2D,
        radius: SearchRadius
    ) async throws -> [Place] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockPlaces
    }
}

struct MockPlanRouteService: PlanRouteServiceProtocol {
    var mockRoutes: [SpotRoute] = []
    var shouldThrowError: Bool = false

    func calculateRoutes(for spots: [PlanSpot]) async throws -> RouteCalculationResult {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return RouteCalculationResult(routes: mockRoutes, failures: [])
    }

    func calculateTotalMetrics(from routes: [SpotRoute], spots: [PlanSpot]) -> (totalDistance: Double, totalDuration: TimeInterval) {
        var totalDistance: Double = 0
        var totalDuration: TimeInterval = 0

        for route in routes {
            totalDistance += route.route.distance
            totalDuration += route.route.expectedTravelTime
        }

        for spot in spots {
            totalDuration += spot.estimatedStayDuration
        }

        return (totalDistance, totalDuration)
    }

    func updateSpotRouteInfo(spots: inout [PlanSpot], routes: [SpotRoute]) {
        guard !spots.isEmpty else { return }
        spots[0].routeDistanceFromPrevious = nil
        spots[0].routeTravelTimeFromPrevious = nil

        for route in routes {
            let toIndex = route.toSpotIndex
            if toIndex < spots.count {
                spots[toIndex].routeDistanceFromPrevious = route.route.distance
                spots[toIndex].routeTravelTimeFromPrevious = route.route.expectedTravelTime
            }
        }
    }
}

struct MockPlanGeneratorService: PlanGeneratorServiceProtocol {
    var isAvailable: Bool = false
    var usedWebAPI: Bool = false
    var mockPlan: GeneratedPlan?
    var shouldThrowError: Bool = false

    func generatePlan(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place],
        startPoint: Place,
        startPointName: String?
    ) async throws -> GeneratedPlan {
        if shouldThrowError {
            throw PlanGeneratorError.aiUnavailable
        }
        return mockPlan ?? GeneratedPlan(title: "テストプラン", spots: [])
    }

    func matchGeneratedSpotsWithPlaces(
        generatedSpots: [GeneratedSpotInfo],
        candidatePlaces: [Place]
    ) -> [(spot: GeneratedSpotInfo, place: Place)] {
        var result: [(spot: GeneratedSpotInfo, place: Place)] = []
        for spot in generatedSpots {
            if let place = candidatePlaces.first(where: { $0.name == spot.name }) {
                result.append((spot, place))
            }
        }
        return result
    }

    func getPlacesFromWebAPIResult(generatedSpots: [GeneratedSpotInfo]) -> [Place] {
        return []
    }
}

final class MockLocationCompleterService: LocationCompleterServiceProtocol {
    var suggestions: [SearchSuggestion] = []
    var onSuggestionsUpdated: (([SearchSuggestion]) -> Void)?

    func updateQuery(_ query: String) {}
    func setRegion(_ region: MKCoordinateRegion) {}
    func search(suggestion: SearchSuggestion) async throws -> [Place] { [] }
    func clear() {
        suggestions = []
    }
}

// MARK: - Tests

@MainActor
struct PlanGeneratorViewModelTests {
    // MARK: - Initial State

    @Test func initialState_hasCorrectDefaults() {
        let viewModel = PlanGeneratorViewModel()
        #expect(viewModel.currentStep == .location)
        #expect(viewModel.locationQuery == "")
        #expect(viewModel.selectedLocation == nil)
        #expect(viewModel.searchRadius == .large)
        #expect(viewModel.selectedCategories.isEmpty)
        #expect(viewModel.theme == "")
        #expect(viewModel.generatorState == .idle)
        #expect(viewModel.generatedPlan == nil)
        #expect(viewModel.generatedSpots.isEmpty)
    }

    // MARK: - canProceedToNext

    @Test func canProceedToNext_locationStep_noSelection_returnsFalse() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .location
        viewModel.selectedLocation = nil
        #expect(viewModel.canProceedToNext == false)
    }

    @Test func canProceedToNext_locationStep_withSelection_returnsTrue() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .location
        viewModel.selectedLocation = TestFactory.createMockPlace()
        #expect(viewModel.canProceedToNext == true)
    }

    @Test func canProceedToNext_categoryStep_empty_returnsFalse() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .category
        viewModel.selectedCategories = []
        #expect(viewModel.canProceedToNext == false)
    }

    @Test func canProceedToNext_categoryStep_withSelection_returnsTrue() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .category
        viewModel.selectedCategories = [.scenic]
        #expect(viewModel.canProceedToNext == true)
    }

    @Test func canProceedToNext_themeStep_emptyTheme_returnsFalse() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .theme
        viewModel.theme = ""
        #expect(viewModel.canProceedToNext == false)
    }

    @Test func canProceedToNext_themeStep_whitespaceOnly_returnsFalse() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .theme
        viewModel.theme = "   "
        #expect(viewModel.canProceedToNext == false)
    }

    @Test func canProceedToNext_themeStep_withTheme_returnsTrue() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .theme
        viewModel.theme = "歴史散策"
        #expect(viewModel.canProceedToNext == true)
    }

    @Test func canProceedToNext_confirmStep_alwaysTrue() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .confirm
        #expect(viewModel.canProceedToNext == true)
    }

    // MARK: - nextStep / previousStep

    @Test func nextStep_advancesToNextStep() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .location
        viewModel.nextStep()
        #expect(viewModel.currentStep == .category)
    }

    @Test func nextStep_atLastStep_doesNotChange() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .confirm
        viewModel.nextStep()
        #expect(viewModel.currentStep == .confirm)
    }

    @Test func previousStep_goesBackOneStep() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .category
        viewModel.previousStep()
        #expect(viewModel.currentStep == .location)
    }

    @Test func previousStep_atFirstStep_doesNotChange() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .location
        viewModel.previousStep()
        #expect(viewModel.currentStep == .location)
    }

    // MARK: - Category Selection

    @Test func toggleCategory_addsNewCategory() {
        let viewModel = PlanGeneratorViewModel()
        #expect(viewModel.selectedCategories.isEmpty)
        viewModel.toggleCategory(.scenic)
        #expect(viewModel.selectedCategories.contains(.scenic))
    }

    @Test func toggleCategory_removesExistingCategory() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.selectedCategories = [.scenic]
        viewModel.toggleCategory(.scenic)
        #expect(!viewModel.selectedCategories.contains(.scenic))
    }

    @Test func toggleCategory_canAddMultipleCategories() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.toggleCategory(.scenic)
        viewModel.toggleCategory(.activity)
        #expect(viewModel.selectedCategories.count == 2)
        #expect(viewModel.selectedCategories.contains(.scenic))
        #expect(viewModel.selectedCategories.contains(.activity))
    }

    // MARK: - availableSuggestions

    @Test func availableSuggestions_emptyCategories_returnsEmpty() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.selectedCategories = []
        #expect(viewModel.availableSuggestions.isEmpty)
    }

    @Test func availableSuggestions_withCategories_combinesSuggestions() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.selectedCategories = [.scenic]
        let suggestions = viewModel.availableSuggestions
        #expect(!suggestions.isEmpty)
        #expect(suggestions.contains("歴史巡り"))
    }

    @Test func availableSuggestions_multipleCategories_combinesAll() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.selectedCategories = [.scenic, .activity]
        let suggestions = viewModel.availableSuggestions
        #expect(suggestions.contains("歴史巡り")) // from scenic
        #expect(suggestions.contains("美術館巡り")) // from activity
    }

    // MARK: - selectThemeSuggestion

    @Test func selectThemeSuggestion_setsTheme() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.selectThemeSuggestion("歴史巡り")
        #expect(viewModel.theme == "歴史巡り")
    }

    // MARK: - Editing Spots

    @Test func reorderSpots_updatesOrders() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.generatedSpots = [
            TestFactory.createMockPlanSpot(order: 0, name: "Spot 1"),
            TestFactory.createMockPlanSpot(order: 1, name: "Spot 2"),
            TestFactory.createMockPlanSpot(order: 2, name: "Spot 3")
        ]

        viewModel.reorderSpots(from: IndexSet(integer: 0), to: 3)

        #expect(viewModel.generatedSpots[0].order == 0)
        #expect(viewModel.generatedSpots[1].order == 1)
        #expect(viewModel.generatedSpots[2].order == 2)
    }

    @Test func deleteSpot_byIndexSet_removesAndUpdatesOrders() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.generatedSpots = [
            TestFactory.createMockPlanSpot(order: 0, name: "Spot 1"),
            TestFactory.createMockPlanSpot(order: 1, name: "Spot 2"),
            TestFactory.createMockPlanSpot(order: 2, name: "Spot 3")
        ]

        viewModel.deleteSpot(at: IndexSet(integer: 1))

        #expect(viewModel.generatedSpots.count == 2)
        #expect(viewModel.generatedSpots[0].name == "Spot 1")
        #expect(viewModel.generatedSpots[1].name == "Spot 3")
        #expect(viewModel.generatedSpots[0].order == 0)
        #expect(viewModel.generatedSpots[1].order == 1)
    }

    @Test func deleteSpot_bySpot_removesCorrectSpot() {
        let viewModel = PlanGeneratorViewModel()
        let spot1 = TestFactory.createMockPlanSpot(order: 0, name: "Spot 1")
        let spot2 = TestFactory.createMockPlanSpot(order: 1, name: "Spot 2")
        viewModel.generatedSpots = [spot1, spot2]

        viewModel.deleteSpot(spot1)

        #expect(viewModel.generatedSpots.count == 1)
        #expect(viewModel.generatedSpots[0].name == "Spot 2")
    }

    // MARK: - updateStayDuration

    @Test func updateStayDuration_withinRange_updates() {
        let viewModel = PlanGeneratorViewModel()
        let spot = TestFactory.createMockPlanSpot(stayDuration: 30 * 60) // 30 minutes
        viewModel.generatedSpots = [spot]

        viewModel.updateStayDuration(for: spot, by: 15) // Add 15 minutes

        #expect(viewModel.generatedSpots[0].estimatedStayDuration == 45 * 60) // 45 minutes
    }

    @Test func updateStayDuration_belowMinimum_doesNotUpdate() {
        let viewModel = PlanGeneratorViewModel()
        let spot = TestFactory.createMockPlanSpot(stayDuration: 15 * 60) // 15 minutes (minimum)
        viewModel.generatedSpots = [spot]

        viewModel.updateStayDuration(for: spot, by: -5) // Try to subtract 5 minutes

        #expect(viewModel.generatedSpots[0].estimatedStayDuration == 15 * 60) // Still 15 minutes
    }

    @Test func updateStayDuration_aboveMaximum_doesNotUpdate() {
        let viewModel = PlanGeneratorViewModel()
        let spot = TestFactory.createMockPlanSpot(stayDuration: 180 * 60) // 180 minutes (maximum)
        viewModel.generatedSpots = [spot]

        viewModel.updateStayDuration(for: spot, by: 15) // Try to add 15 minutes

        #expect(viewModel.generatedSpots[0].estimatedStayDuration == 180 * 60) // Still 180 minutes
    }

    // MARK: - toggleFavorite

    @Test func toggleFavorite_togglesFlag() {
        let viewModel = PlanGeneratorViewModel()
        let spot = TestFactory.createMockPlanSpot(isFavorite: false)
        viewModel.generatedSpots = [spot]

        viewModel.toggleFavorite(for: spot)

        #expect(viewModel.generatedSpots[0].isFavorite == true)
    }

    @Test func toggleFavorite_unfavorites() {
        let viewModel = PlanGeneratorViewModel()
        let spot = TestFactory.createMockPlanSpot(isFavorite: true)
        viewModel.generatedSpots = [spot]

        viewModel.toggleFavorite(for: spot)

        #expect(viewModel.generatedSpots[0].isFavorite == false)
    }

    // MARK: - Title Editing

    @Test func startEditingTitle_setsEditedTitleAndFlag() {
        let viewModel = PlanGeneratorViewModel()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        viewModel.generatedPlan = SightseeingPlan(
            title: "テストプラン",
            theme: "テーマ",
            categories: [.scenic],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        viewModel.startEditingTitle()

        #expect(viewModel.editedTitle == "テストプラン")
        #expect(viewModel.isEditingTitle == true)
    }

    @Test func saveTitle_updatesPlanTitle() {
        let viewModel = PlanGeneratorViewModel()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        viewModel.generatedPlan = SightseeingPlan(
            title: "古いタイトル",
            theme: "テーマ",
            categories: [.scenic],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )
        viewModel.editedTitle = "新しいタイトル"
        viewModel.isEditingTitle = true

        viewModel.saveTitle()

        #expect(viewModel.generatedPlan?.title == "新しいタイトル")
        #expect(viewModel.isEditingTitle == false)
    }

    // MARK: - showSpotDetail

    @Test func showSpotDetail_setsSelectedSpotAndShowsSheet() {
        let viewModel = PlanGeneratorViewModel()
        let spot = TestFactory.createMockPlanSpot()

        viewModel.showSpotDetail(spot)

        #expect(viewModel.selectedSpotForDetail?.id == spot.id)
        #expect(viewModel.showSpotDetailSheet == true)
    }

    // MARK: - addSpot

    @Test func addSpot_addsToEndWithCorrectOrder() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.generatedSpots = [
            TestFactory.createMockPlanSpot(order: 0, name: "Existing")
        ]
        viewModel.showAddSpotSheet = true

        let newPlace = TestFactory.createMockPlace(name: "New Place")
        viewModel.addSpot(newPlace)

        #expect(viewModel.generatedSpots.count == 2)
        #expect(viewModel.generatedSpots[1].name == "New Place")
        #expect(viewModel.generatedSpots[1].order == 1)
        #expect(viewModel.showAddSpotSheet == false)
    }

    // MARK: - reset

    @Test func reset_resetsAllState() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.currentStep = .confirm
        viewModel.locationQuery = "Tokyo"
        viewModel.selectedLocation = TestFactory.createMockPlace()
        viewModel.selectedCategories = [.scenic, .activity]
        viewModel.theme = "歴史散策"
        viewModel.generatorState = .completed
        viewModel.generatedSpots = [TestFactory.createMockPlanSpot()]

        viewModel.reset()

        #expect(viewModel.currentStep == .location)
        #expect(viewModel.locationQuery == "")
        #expect(viewModel.selectedLocation == nil)
        #expect(viewModel.searchRadius == .large)
        #expect(viewModel.selectedCategories.isEmpty)
        #expect(viewModel.theme == "")
        #expect(viewModel.generatorState == .idle)
        #expect(viewModel.generatedPlan == nil)
        #expect(viewModel.generatedSpots.isEmpty)
        #expect(viewModel.viewMode == .timeline)
    }

    // MARK: - selectLocation

    @Test func selectLocation_setsLocationAndClearsSuggestions() {
        let viewModel = PlanGeneratorViewModel()
        let place = TestFactory.createMockPlace(name: "東京駅")
        viewModel.locationSuggestions = [TestFactory.createMockPlace()]

        viewModel.selectLocation(place)

        #expect(viewModel.selectedLocation?.name == "東京駅")
        #expect(viewModel.locationQuery == "東京駅")
        #expect(viewModel.locationSuggestions.isEmpty)
    }

    // MARK: - ViewMode

    @Test func viewMode_defaultIsTimeline() {
        let viewModel = PlanGeneratorViewModel()
        #expect(viewModel.viewMode == .timeline)
    }

    @Test func viewMode_canBeChanged() {
        let viewModel = PlanGeneratorViewModel()
        viewModel.viewMode = .map
        #expect(viewModel.viewMode == .map)
    }
}
