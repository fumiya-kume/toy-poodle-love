import CoreLocation
import Foundation
import Testing
@testable import VideoOverlayViewer

@MainActor
struct ScenarioWriterStateTests {
    // MARK: - Initial State Tests

    @Test func initialState_hasCorrectDefaults() {
        let state = ScenarioWriterState()

        #expect(state.selectedTab == .pipeline)
        #expect(state.isLoadingTextGeneration == false)
        #expect(state.isLoadingGeocode == false)
        #expect(state.isLoadingRouteOptimize == false)
        #expect(state.isLoadingPipeline == false)
        #expect(state.isLoadingRouteGenerate == false)
        #expect(state.isLoadingScenario == false)
        #expect(state.isLoadingScenarioIntegrate == false)
    }

    @Test func initialState_textGenerationPrompt_isEmpty() {
        let state = ScenarioWriterState()
        #expect(state.textGenerationPrompt == "")
    }

    @Test func initialState_selectedTextModel_isGemini() {
        let state = ScenarioWriterState()
        #expect(state.selectedTextModel == .gemini)
    }

    @Test func initialState_geocodeAddresses_isEmpty() {
        let state = ScenarioWriterState()
        #expect(state.geocodeAddresses == "")
    }

    @Test func initialState_routeWaypoints_isEmpty() {
        let state = ScenarioWriterState()
        #expect(state.routeWaypoints.isEmpty)
    }

    @Test func initialState_selectedTravelMode_isDriving() {
        let state = ScenarioWriterState()
        #expect(state.selectedTravelMode == .driving)
    }

    @Test func initialState_optimizeWaypointOrder_isTrue() {
        let state = ScenarioWriterState()
        #expect(state.optimizeWaypointOrder == true)
    }

    @Test func initialState_pipelineSpotCount_isFive() {
        let state = ScenarioWriterState()
        #expect(state.pipelineSpotCount == 5)
    }

    @Test func initialState_scenarioSpots_isEmpty() {
        let state = ScenarioWriterState()
        #expect(state.scenarioSpots.isEmpty)
    }

    @Test func initialState_scenarioModels_isBoth() {
        let state = ScenarioWriterState()
        #expect(state.scenarioModels == .both)
    }

    @Test func initialState_lastError_isNil() {
        let state = ScenarioWriterState()
        #expect(state.lastError == nil)
    }

    @Test func initialState_showErrorAlert_isFalse() {
        let state = ScenarioWriterState()
        #expect(state.showErrorAlert == false)
    }

    // MARK: - Waypoint Helper Tests

    @Test func addWaypoint_appendsWaypoint_whenAddressNotEmpty() {
        let state = ScenarioWriterState()

        state.addWaypoint("東京駅")

        #expect(state.routeWaypoints.count == 1)
        #expect(state.routeWaypoints[0].address == "東京駅")
    }

    @Test func addWaypoint_doesNothing_whenAddressEmpty() {
        let state = ScenarioWriterState()

        state.addWaypoint("")

        #expect(state.routeWaypoints.isEmpty)
    }

    @Test func addWaypoint_appendsMultipleWaypoints() {
        let state = ScenarioWriterState()

        state.addWaypoint("東京駅")
        state.addWaypoint("新宿駅")
        state.addWaypoint("渋谷駅")

        #expect(state.routeWaypoints.count == 3)
        #expect(state.routeWaypoints[0].address == "東京駅")
        #expect(state.routeWaypoints[1].address == "新宿駅")
        #expect(state.routeWaypoints[2].address == "渋谷駅")
    }

    @Test func removeWaypoint_removesAtIndex() {
        let state = ScenarioWriterState()
        state.addWaypoint("東京駅")
        state.addWaypoint("新宿駅")
        state.addWaypoint("渋谷駅")

        state.removeWaypoint(at: 1)

        #expect(state.routeWaypoints.count == 2)
        #expect(state.routeWaypoints[0].address == "東京駅")
        #expect(state.routeWaypoints[1].address == "渋谷駅")
    }

    @Test func removeWaypoint_doesNothing_whenIndexOutOfBounds() {
        let state = ScenarioWriterState()
        state.addWaypoint("東京駅")

        state.removeWaypoint(at: 5)

        #expect(state.routeWaypoints.count == 1)
    }

    @Test func removeWaypoint_doesNothing_whenNegativeIndex() {
        let state = ScenarioWriterState()
        state.addWaypoint("東京駅")

        state.removeWaypoint(at: -1)

        #expect(state.routeWaypoints.count == 1)
    }

    // MARK: - Scenario Spot Helper Tests

    @Test func addScenarioSpot_appendsSpot_whenNameNotEmpty() {
        let state = ScenarioWriterState()

        state.addScenarioSpot(
            name: "東京タワー",
            type: .waypoint,
            description: "観光スポット",
            point: "東京都港区芝公園"
        )

        #expect(state.scenarioSpots.count == 1)
        #expect(state.scenarioSpots[0].name == "東京タワー")
        #expect(state.scenarioSpots[0].type == .waypoint)
        #expect(state.scenarioSpots[0].description == "観光スポット")
        #expect(state.scenarioSpots[0].point == "東京都港区芝公園")
    }

    @Test func addScenarioSpot_doesNothing_whenNameEmpty() {
        let state = ScenarioWriterState()

        state.addScenarioSpot(
            name: "",
            type: .waypoint,
            description: "Description",
            point: "Point"
        )

        #expect(state.scenarioSpots.isEmpty)
    }

    @Test func addScenarioSpot_normalizesEmptyDescriptionToNil() {
        let state = ScenarioWriterState()

        state.addScenarioSpot(
            name: "スポット",
            type: .waypoint,
            description: "",
            point: "Point"
        )

        #expect(state.scenarioSpots[0].description == nil)
    }

    @Test func addScenarioSpot_normalizesEmptyPointToNil() {
        let state = ScenarioWriterState()

        state.addScenarioSpot(
            name: "スポット",
            type: .waypoint,
            description: "Desc",
            point: ""
        )

        #expect(state.scenarioSpots[0].point == nil)
    }

    @Test func addScenarioSpot_handlesNilValuesCorrectly() {
        let state = ScenarioWriterState()

        state.addScenarioSpot(
            name: "スポット",
            type: .start,
            description: nil,
            point: nil
        )

        #expect(state.scenarioSpots.count == 1)
        #expect(state.scenarioSpots[0].description == nil)
        #expect(state.scenarioSpots[0].point == nil)
    }

    @Test func removeScenarioSpot_removesAtIndex() {
        let state = ScenarioWriterState()
        state.addScenarioSpot(name: "スポット1", type: .start, description: nil, point: nil)
        state.addScenarioSpot(name: "スポット2", type: .waypoint, description: nil, point: nil)
        state.addScenarioSpot(name: "スポット3", type: .destination, description: nil, point: nil)

        state.removeScenarioSpot(at: 1)

        #expect(state.scenarioSpots.count == 2)
        #expect(state.scenarioSpots[0].name == "スポット1")
        #expect(state.scenarioSpots[1].name == "スポット3")
    }

    @Test func removeScenarioSpot_doesNothing_whenIndexOutOfBounds() {
        let state = ScenarioWriterState()
        state.addScenarioSpot(name: "スポット", type: .waypoint, description: nil, point: nil)

        state.removeScenarioSpot(at: 10)

        #expect(state.scenarioSpots.count == 1)
    }

    // MARK: - Error Handling Tests

    @Test func dismissError_clearsLastError() {
        let state = ScenarioWriterState()
        state.showErrorAlert = true

        state.dismissError()

        #expect(state.showErrorAlert == false)
        #expect(state.lastError == nil)
    }

    // MARK: - Display Scenarios Tests

    @Test func displayScenarios_returnsEmptyArray_whenNoScenarioResult() {
        let state = ScenarioWriterState()

        #expect(state.displayScenarios.isEmpty)
    }

    // MARK: - Property Modification Tests

    @Test func selectedTab_canBeChanged() {
        let state = ScenarioWriterState()

        state.selectedTab = .textGeneration
        #expect(state.selectedTab == .textGeneration)

        state.selectedTab = .geocode
        #expect(state.selectedTab == .geocode)

        state.selectedTab = .map
        #expect(state.selectedTab == .map)
    }

    @Test func selectedTextModel_canBeChanged() {
        let state = ScenarioWriterState()

        state.selectedTextModel = .qwen
        #expect(state.selectedTextModel == .qwen)

        state.selectedTextModel = .gemini
        #expect(state.selectedTextModel == .gemini)
    }

    @Test func selectedTravelMode_canBeChanged() {
        let state = ScenarioWriterState()

        state.selectedTravelMode = .walking
        #expect(state.selectedTravelMode == .walking)

        state.selectedTravelMode = .bicycling
        #expect(state.selectedTravelMode == .bicycling)

        state.selectedTravelMode = .transit
        #expect(state.selectedTravelMode == .transit)
    }

    @Test func optimizeWaypointOrder_canBeToggled() {
        let state = ScenarioWriterState()
        #expect(state.optimizeWaypointOrder == true)

        state.optimizeWaypointOrder = false
        #expect(state.optimizeWaypointOrder == false)

        state.optimizeWaypointOrder = true
        #expect(state.optimizeWaypointOrder == true)
    }

    @Test func pipelineSpotCount_canBeChanged() {
        let state = ScenarioWriterState()

        state.pipelineSpotCount = 10
        #expect(state.pipelineSpotCount == 10)

        state.pipelineSpotCount = 3
        #expect(state.pipelineSpotCount == 3)
    }

    @Test func scenarioModels_canBeChanged() {
        let state = ScenarioWriterState()

        state.scenarioModels = .gemini
        #expect(state.scenarioModels == .gemini)

        state.scenarioModels = .qwen
        #expect(state.scenarioModels == .qwen)

        state.scenarioModels = .both
        #expect(state.scenarioModels == .both)
    }

    // MARK: - Input Validation Guard Tests

    @Test func textGenerationPrompt_storesValue() {
        let state = ScenarioWriterState()

        state.textGenerationPrompt = "Test prompt"

        #expect(state.textGenerationPrompt == "Test prompt")
    }

    @Test func geocodeAddresses_storesValue() {
        let state = ScenarioWriterState()

        state.geocodeAddresses = "東京駅\n新宿駅\n渋谷駅"

        #expect(state.geocodeAddresses == "東京駅\n新宿駅\n渋谷駅")
    }

    @Test func pipelineStartPoint_storesValue() {
        let state = ScenarioWriterState()

        state.pipelineStartPoint = "東京駅"

        #expect(state.pipelineStartPoint == "東京駅")
    }

    @Test func pipelinePurpose_storesValue() {
        let state = ScenarioWriterState()

        state.pipelinePurpose = "観光"

        #expect(state.pipelinePurpose == "観光")
    }

    @Test func routeGenerateStartPoint_storesValue() {
        let state = ScenarioWriterState()

        state.routeGenerateStartPoint = "大阪駅"

        #expect(state.routeGenerateStartPoint == "大阪駅")
    }

    @Test func scenarioRouteName_storesValue() {
        let state = ScenarioWriterState()

        state.scenarioRouteName = "東京観光ルート"

        #expect(state.scenarioRouteName == "東京観光ルート")
    }

    @Test func scenarioLanguage_storesValue() {
        let state = ScenarioWriterState()

        state.scenarioLanguage = "ja"

        #expect(state.scenarioLanguage == "ja")
    }

    // MARK: - Loading State Tests

    @Test func loadingStates_canBeModified() {
        let state = ScenarioWriterState()

        state.isLoadingTextGeneration = true
        #expect(state.isLoadingTextGeneration == true)

        state.isLoadingGeocode = true
        #expect(state.isLoadingGeocode == true)

        state.isLoadingRouteOptimize = true
        #expect(state.isLoadingRouteOptimize == true)

        state.isLoadingPipeline = true
        #expect(state.isLoadingPipeline == true)

        state.isLoadingRouteGenerate = true
        #expect(state.isLoadingRouteGenerate == true)

        state.isLoadingScenario = true
        #expect(state.isLoadingScenario == true)

        state.isLoadingScenarioIntegrate = true
        #expect(state.isLoadingScenarioIntegrate == true)
    }

    // MARK: - MapSpots Tests

    @Test func mapSpots_initiallyEmpty() {
        let state = ScenarioWriterState()
        #expect(state.mapSpots.isEmpty)
    }

    @Test func mapSpots_canBeSet() {
        let state = ScenarioWriterState()
        let spot = MapSpot(
            name: "テストスポット",
            coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            type: .waypoint,
            address: "東京都千代田区",
            description: "テスト",
            order: 1
        )

        state.mapSpots = [spot]

        #expect(state.mapSpots.count == 1)
        #expect(state.mapSpots[0].name == "テストスポット")
    }

    // MARK: - Results Tests

    @Test func results_initiallyNil() {
        let state = ScenarioWriterState()

        #expect(state.textGenerationResult == nil)
        #expect(state.geocodeResult == nil)
        #expect(state.routeOptimizeResult == nil)
        #expect(state.pipelineResult == nil)
        #expect(state.routeGenerateResult == nil)
        #expect(state.scenarioResult == nil)
        #expect(state.scenarioIntegrationResult == nil)
    }
}
