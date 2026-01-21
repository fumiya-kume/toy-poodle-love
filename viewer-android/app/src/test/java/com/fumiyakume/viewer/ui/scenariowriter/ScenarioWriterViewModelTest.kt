package com.fumiyakume.viewer.ui.scenariowriter

import com.fumiyakume.viewer.data.network.ApiError
import com.fumiyakume.viewer.data.network.ApiResult
import com.fumiyakume.viewer.data.network.GeneratedSpot
import com.fumiyakume.viewer.data.network.GeocodedPlace
import com.fumiyakume.viewer.data.network.LatLng
import com.fumiyakume.viewer.data.network.PipelineResponse
import com.fumiyakume.viewer.data.network.RouteGenerationResponse
import com.fumiyakume.viewer.data.network.RouteOptimizeResponse
import com.fumiyakume.viewer.data.network.RouteSpot
import com.fumiyakume.viewer.data.network.RouteWaypoint
import com.fumiyakume.viewer.data.network.ScenarioIntegrationOutput
import com.fumiyakume.viewer.data.network.ScenarioOutput
import com.fumiyakume.viewer.data.network.SpotScenarioResult
import com.fumiyakume.viewer.data.repository.ScenarioRepository
import com.fumiyakume.viewer.test.MainDispatcherRule
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ScenarioWriterViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun updatePipelineSpotCount_clampsToRange() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>(relaxed = true)
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updatePipelineSpotCount(1)
        assertEquals(3, viewModel.uiState.value.pipelineSpotCount)

        viewModel.updatePipelineSpotCount(10)
        assertEquals(8, viewModel.uiState.value.pipelineSpotCount)
    }

    @Test
    fun addWaypoint_trimsAndClearsInput() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>(relaxed = true)
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updateWaypointInput("  Tokyo Station  ")
        viewModel.addWaypoint()

        assertEquals(listOf(RouteWaypoint(address = "Tokyo Station")), viewModel.uiState.value.routeWaypoints)
        assertEquals("", viewModel.uiState.value.waypointInput)
    }

    @Test
    fun addWaypoint_doesNothing_whenInputBlank() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>(relaxed = true)
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updateWaypointInput("   ")
        viewModel.addWaypoint()

        assertTrue(viewModel.uiState.value.routeWaypoints.isEmpty())
        assertEquals("   ", viewModel.uiState.value.waypointInput)
    }

    @Test
    fun removeWaypoint_removesByIndex() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>(relaxed = true)
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updateWaypointInput("a")
        viewModel.addWaypoint()
        viewModel.updateWaypointInput("b")
        viewModel.addWaypoint()

        viewModel.removeWaypoint(0)

        assertEquals(listOf(RouteWaypoint(address = "b")), viewModel.uiState.value.routeWaypoints)
    }

    @Test
    fun runPipeline_success_setsResult() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        val startPointSlot = slot<String>()
        val purposeSlot = slot<String>()
        val spotCountSlot = slot<Int>()
        val modelSlot = slot<String>()
        val response = PipelineResponse(
            success = true,
            routeName = "route",
            spots = listOf(GeneratedSpot(name = "A", type = "start", description = "desc"))
        )
        coEvery {
            repository.runPipeline(
                startPoint = capture(startPointSlot),
                purpose = capture(purposeSlot),
                spotCount = capture(spotCountSlot),
                model = capture(modelSlot)
            )
        } returns ApiResult.Success(response)

        viewModel.updatePipelineStartPoint("start")
        viewModel.updatePipelinePurpose("purpose")
        viewModel.runPipeline()
        advanceUntilIdle()

        assertEquals("start", startPointSlot.captured)
        assertEquals("purpose", purposeSlot.captured)
        assertEquals(5, spotCountSlot.captured)
        assertEquals("gemini", modelSlot.captured)

        assertEquals(response, viewModel.uiState.value.pipelineResult)
        assertFalse(viewModel.uiState.value.isLoadingPipeline)
        assertNull(viewModel.errorMessage.value)
    }

    @Test
    fun runPipeline_error_setsErrorMessage() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        coEvery { repository.runPipeline(any(), any(), any(), any()) } returns ApiResult.Error(ApiError.NetworkError)

        viewModel.updatePipelineStartPoint("start")
        viewModel.updatePipelinePurpose("purpose")
        viewModel.runPipeline()
        advanceUntilIdle()

        assertNull(viewModel.uiState.value.pipelineResult)
        assertFalse(viewModel.uiState.value.isLoadingPipeline)
        assertEquals("ネットワークに接続できません", viewModel.errorMessage.value)
    }

    @Test
    fun generateText_usesSelectedModel_andStoresResultModel() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        coEvery { repository.generateTextWithGemini("hi") } returns ApiResult.Success("ok")

        viewModel.updateTextGenerationPrompt("hi")
        viewModel.updateTextGenerationModel(AIModel.GEMINI)
        viewModel.generateText()
        advanceUntilIdle()

        assertEquals("ok", viewModel.uiState.value.textGenerationResult)
        assertEquals(AIModel.GEMINI, viewModel.uiState.value.textGenerationResultModel)

        coVerify(exactly = 1) { repository.generateTextWithGemini("hi") }
        coVerify(exactly = 0) { repository.generateTextWithQwen(any()) }
    }

    @Test
    fun geocode_splitsAndTrimsAddresses_beforeCallingRepository() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        val addressesSlot = slot<List<String>>()
        val places = listOf(
            GeocodedPlace(
                inputAddress = "a",
                formattedAddress = "a formatted",
                location = LatLng(latitude = 1.0, longitude = 2.0)
            )
        )
        coEvery { repository.geocode(capture(addressesSlot)) } returns ApiResult.Success(places)

        viewModel.updateGeocodeAddresses(" a \n\n b \n")
        viewModel.geocode()
        advanceUntilIdle()

        assertEquals(listOf("a", "b"), addressesSlot.captured)
        assertEquals(places, viewModel.uiState.value.geocodeResult)
        assertNull(viewModel.errorMessage.value)
    }

    @Test
    fun geocode_setsError_whenNoAddresses_andDoesNotCallRepository() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updateGeocodeAddresses("\n \n")
        viewModel.geocode()
        advanceUntilIdle()

        assertEquals("住所を入力してください", viewModel.errorMessage.value)
        assertFalse(viewModel.uiState.value.isLoadingGeocode)
        coVerify(exactly = 0) { repository.geocode(any()) }
    }

    @Test
    fun optimizeRoute_requiresAtLeastTwoWaypoints() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updateWaypointInput("a")
        viewModel.addWaypoint()

        viewModel.optimizeRoute()
        advanceUntilIdle()

        assertEquals("少なくとも2つのウェイポイントが必要です", viewModel.errorMessage.value)
        assertFalse(viewModel.uiState.value.isLoadingRouteOptimize)
        coVerify(exactly = 0) { repository.optimizeRoute(any(), any(), any(), any(), any()) }
    }

    @Test
    fun optimizeRoute_callsRepositoryWithOriginDestinationAndIntermediates() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.updateWaypointInput("origin")
        viewModel.addWaypoint()
        viewModel.updateWaypointInput("mid")
        viewModel.addWaypoint()
        viewModel.updateWaypointInput("destination")
        viewModel.addWaypoint()
        viewModel.updateTravelMode(TravelMode.WALK)
        viewModel.updateOptimizeWaypointOrder(false)

        val originSlot = slot<RouteWaypoint>()
        val destinationSlot = slot<RouteWaypoint>()
        val intermediatesSlot = slot<List<RouteWaypoint>>()
        val travelModeSlot = slot<String>()
        val optimizeSlot = slot<Boolean>()
        val response = RouteOptimizeResponse(success = true)
        coEvery {
            repository.optimizeRoute(
                origin = capture(originSlot),
                destination = capture(destinationSlot),
                intermediates = capture(intermediatesSlot),
                travelMode = capture(travelModeSlot),
                optimizeWaypointOrder = capture(optimizeSlot)
            )
        } returns ApiResult.Success(response)

        viewModel.optimizeRoute()
        advanceUntilIdle()

        assertEquals(RouteWaypoint(address = "origin"), originSlot.captured)
        assertEquals(RouteWaypoint(address = "destination"), destinationSlot.captured)
        assertEquals(listOf(RouteWaypoint(address = "mid")), intermediatesSlot.captured)
        assertEquals("WALK", travelModeSlot.captured)
        assertFalse(optimizeSlot.captured)
        assertEquals(response, viewModel.uiState.value.routeOptimizeResult)
    }

    @Test
    fun createSpotsFromPipeline_mapsGeneratedSpots_andSelectsScenarioTab() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        val response = PipelineResponse(
            success = true,
            routeName = "route",
            spots = listOf(
                GeneratedSpot(name = "A", type = "start", description = "a"),
                GeneratedSpot(name = "B", type = "waypoint", description = "b"),
                GeneratedSpot(name = "C", type = "destination", description = "c")
            )
        )
        coEvery { repository.runPipeline(any(), any(), any(), any()) } returns ApiResult.Success(response)

        viewModel.updatePipelineStartPoint("start")
        viewModel.updatePipelinePurpose("purpose")
        viewModel.runPipeline()
        advanceUntilIdle()

        viewModel.createSpotsFromPipeline()

        assertEquals(ScenarioWriterTab.SCENARIO_GENERATE, viewModel.selectedTab.value)
        assertEquals("route", viewModel.uiState.value.scenarioRouteName)
        assertEquals(
            listOf(
                RouteSpot(name = "A", type = "start", description = "a"),
                RouteSpot(name = "B", type = "waypoint", description = "b"),
                RouteSpot(name = "C", type = "destination", description = "c")
            ),
            viewModel.uiState.value.scenarioSpots
        )
    }

    @Test
    fun createMapSpotsFromPipeline_buildsMapSpots_andSelectsMapTab() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        val response = PipelineResponse(
            success = true,
            routeName = "route",
            spots = listOf(
                GeneratedSpot(name = "A", type = "start", description = "a"),
                GeneratedSpot(name = "B", type = "waypoint", description = "b")
            )
        )
        coEvery { repository.runPipeline(any(), any(), any(), any()) } returns ApiResult.Success(response)

        viewModel.updatePipelineStartPoint("start")
        viewModel.updatePipelinePurpose("purpose")
        viewModel.runPipeline()
        advanceUntilIdle()

        viewModel.createMapSpotsFromPipeline()

        assertEquals(ScenarioWriterTab.SCENARIO_MAP, viewModel.selectedTab.value)
        assertEquals(
            listOf(
                MapSpot(
                    id = "pipeline_0",
                    name = "A",
                    type = "start",
                    description = "a",
                    address = null,
                    coordinate = LatLng(35.681236, 139.767125)
                ),
                MapSpot(
                    id = "pipeline_1",
                    name = "B",
                    type = "waypoint",
                    description = "b",
                    address = null,
                    coordinate = LatLng(35.681236, 139.767125)
                )
            ),
            viewModel.uiState.value.mapSpots
        )
    }

    @Test
    fun createSpotsFromRouteGeneration_mapsSpots_andSelectsScenarioTab() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        val response = RouteGenerationResponse(
            success = true,
            spots = listOf(
                GeneratedSpot(name = "A", type = "start", description = "a"),
                GeneratedSpot(name = "B", type = "waypoint", description = "b"),
                GeneratedSpot(name = "C", type = "destination", description = "c")
            )
        )
        coEvery { repository.generateRoute(any(), any(), any(), any()) } returns ApiResult.Success(response)

        viewModel.updateRouteGenerateStartPoint("start")
        viewModel.updateRouteGeneratePurpose("purpose")
        viewModel.generateRoute()
        advanceUntilIdle()

        viewModel.createSpotsFromRouteGeneration()

        assertEquals(ScenarioWriterTab.SCENARIO_GENERATE, viewModel.selectedTab.value)
        assertEquals(
            listOf(
                RouteSpot(name = "A", type = "start", description = "a"),
                RouteSpot(name = "B", type = "waypoint", description = "b"),
                RouteSpot(name = "C", type = "destination", description = "c")
            ),
            viewModel.uiState.value.scenarioSpots
        )
    }

    @Test
    fun integrateScenarios_setsError_whenNoScenarioResult_andDoesNotCallRepository() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        viewModel.integrateScenarios()
        advanceUntilIdle()

        assertEquals("統合するシナリオがありません", viewModel.errorMessage.value)
        assertFalse(viewModel.uiState.value.isLoadingScenarioIntegrate)
        coVerify(exactly = 0) { repository.integrateScenario(any()) }
    }

    @Test
    fun integrateScenarios_filtersNullScenarios_beforeCallingRepository() = runTest(mainDispatcherRule.dispatcher) {
        val repository = mockk<ScenarioRepository>()
        val viewModel = ScenarioWriterViewModel(repository)

        val scenarioOutput = ScenarioOutput(
            success = true,
            spotScenarios = listOf(
                SpotScenarioResult(spotName = "A", spotType = "start", scenario = null),
                SpotScenarioResult(spotName = "B", spotType = "waypoint", scenario = "text")
            )
        )
        coEvery { repository.generateScenario(any(), any(), any(), any()) } returns ApiResult.Success(scenarioOutput)

        val integratedOutput = ScenarioIntegrationOutput(success = true, integratedScript = "merged")
        val scenarioListSlot = slot<List<com.fumiyakume.viewer.data.network.SpotScenario>>()
        coEvery { repository.integrateScenario(capture(scenarioListSlot)) } returns ApiResult.Success(integratedOutput)

        viewModel.updateScenarioRouteName("route")
        viewModel.addScenarioSpot(RouteSpot(name = "A", type = "start"))
        viewModel.generateScenario()
        advanceUntilIdle()

        viewModel.integrateScenarios()
        advanceUntilIdle()

        assertEquals(
            listOf(com.fumiyakume.viewer.data.network.SpotScenario(spotName = "B", scenario = "text")),
            scenarioListSlot.captured
        )
        assertEquals(integratedOutput, viewModel.uiState.value.scenarioIntegrationResult)
    }
}
