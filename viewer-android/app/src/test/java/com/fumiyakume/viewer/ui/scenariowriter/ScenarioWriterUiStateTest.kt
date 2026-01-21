package com.fumiyakume.viewer.ui.scenariowriter

import com.fumiyakume.viewer.data.network.RouteSpot
import com.fumiyakume.viewer.data.network.RouteWaypoint
import com.fumiyakume.viewer.data.network.ScenarioOutput
import com.fumiyakume.viewer.data.network.SpotScenarioResult
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ScenarioWriterUiStateTest {

    @Test
    fun canRunPipeline_requiresStartPointAndPurpose() {
        assertFalse(ScenarioWriterUiState().canRunPipeline)
        assertFalse(ScenarioWriterUiState(pipelineStartPoint = "start").canRunPipeline)
        assertTrue(ScenarioWriterUiState(pipelineStartPoint = "start", pipelinePurpose = "purpose").canRunPipeline)
    }

    @Test
    fun canGenerateRoute_requiresStartPointAndPurpose() {
        assertFalse(ScenarioWriterUiState().canGenerateRoute)
        assertFalse(ScenarioWriterUiState(routeGenerateStartPoint = "start").canGenerateRoute)
        assertTrue(ScenarioWriterUiState(routeGenerateStartPoint = "start", routeGeneratePurpose = "purpose").canGenerateRoute)
    }

    @Test
    fun canGenerateScenario_requiresRouteNameAndAtLeastOneSpot() {
        val withRouteOnly = ScenarioWriterUiState(scenarioRouteName = "route")
        val withSpotsOnly = ScenarioWriterUiState(scenarioSpots = listOf(RouteSpot(name = "spot", type = "start")))
        val withBoth = ScenarioWriterUiState(
            scenarioRouteName = "route",
            scenarioSpots = listOf(RouteSpot(name = "spot", type = "start"))
        )

        assertFalse(withRouteOnly.canGenerateScenario)
        assertFalse(withSpotsOnly.canGenerateScenario)
        assertTrue(withBoth.canGenerateScenario)
    }

    @Test
    fun canIntegrateScenarios_isTrue_whenAnySpotScenarioHasScenario() {
        val allNull = ScenarioWriterUiState(
            scenarioResult = ScenarioOutput(
                success = true,
                spotScenarios = listOf(
                    SpotScenarioResult(spotName = "A", spotType = "start", scenario = null),
                    SpotScenarioResult(spotName = "B", spotType = "waypoint", scenario = null)
                )
            )
        )
        val hasOne = ScenarioWriterUiState(
            scenarioResult = ScenarioOutput(
                success = true,
                spotScenarios = listOf(
                    SpotScenarioResult(spotName = "A", spotType = "start", scenario = null),
                    SpotScenarioResult(spotName = "B", spotType = "waypoint", scenario = "text")
                )
            )
        )

        assertFalse(allNull.canIntegrateScenarios)
        assertTrue(hasOne.canIntegrateScenarios)
    }

    @Test
    fun isLoading_isTrue_whenAnyLoadingFlagTrue() {
        assertFalse(ScenarioWriterUiState().isLoading)
        assertTrue(ScenarioWriterUiState(isLoadingPipeline = true).isLoading)
        assertTrue(ScenarioWriterUiState(isLoadingGeocode = true).isLoading)
        assertTrue(ScenarioWriterUiState(isLoadingRouteOptimize = true).isLoading)
    }

    @Test
    fun canGeocode_canGenerateText_and_canOptimizeRoute_work() {
        assertFalse(ScenarioWriterUiState().canGeocode)
        assertTrue(ScenarioWriterUiState(geocodeAddresses = "addr").canGeocode)

        assertFalse(ScenarioWriterUiState().canGenerateText)
        assertTrue(ScenarioWriterUiState(textGenerationPrompt = "prompt").canGenerateText)

        assertFalse(ScenarioWriterUiState().canOptimizeRoute)
        assertTrue(
            ScenarioWriterUiState(
                routeWaypoints = listOf(RouteWaypoint(address = "a"), RouteWaypoint(address = "b"))
            ).canOptimizeRoute
        )
    }
}

