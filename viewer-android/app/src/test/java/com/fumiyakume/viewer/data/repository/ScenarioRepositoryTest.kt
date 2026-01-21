package com.fumiyakume.viewer.data.repository

import com.fumiyakume.viewer.data.network.ApiError
import com.fumiyakume.viewer.data.network.ApiResult
import com.fumiyakume.viewer.data.network.ApiService
import com.fumiyakume.viewer.data.network.GeocodeResponse
import com.fumiyakume.viewer.data.network.GeocodedPlace
import com.fumiyakume.viewer.data.network.LatLng
import com.fumiyakume.viewer.data.network.PipelineResponse
import com.fumiyakume.viewer.data.network.RouteGenerateInput
import com.fumiyakume.viewer.data.network.RouteGenerationResponse
import com.fumiyakume.viewer.data.network.RouteOptimizeResponse
import com.fumiyakume.viewer.data.network.RouteSpot
import com.fumiyakume.viewer.data.network.RouteWaypoint
import com.fumiyakume.viewer.data.network.ScenarioIntegrationOutput
import com.fumiyakume.viewer.data.network.ScenarioOutput
import com.fumiyakume.viewer.data.network.ScenarioRequest
import com.fumiyakume.viewer.data.network.ScenarioRoute
import com.fumiyakume.viewer.data.network.SpotScenario
import com.fumiyakume.viewer.data.network.SpotScenarioResponse
import com.fumiyakume.viewer.data.network.TextGenerationResponse
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ScenarioRepositoryTest {

    private val apiService = mockk<ApiService>()
    private val repository = ScenarioRepository(apiService)

    @Test
    fun generateTextWithQwen_returnsSuccess_whenResponseHasResult() = runTest {
        coEvery { apiService.generateTextWithQwen(any()) } returns TextGenerationResponse(
            success = true,
            result = "hello"
        )

        val result = repository.generateTextWithQwen("prompt")

        assertEquals(ApiResult.Success("hello"), result)
    }

    @Test
    fun generateTextWithQwen_returnsApiResponseError_whenResponseIsFailure() = runTest {
        coEvery { apiService.generateTextWithQwen(any()) } returns TextGenerationResponse(
            success = false,
            error = "bad"
        )

        val result = repository.generateTextWithQwen("prompt")

        assertApiResponseError(result, "bad")
    }

    @Test
    fun generateTextWithQwen_returnsDefaultApiResponseError_whenErrorIsMissing() = runTest {
        coEvery { apiService.generateTextWithQwen(any()) } returns TextGenerationResponse(
            success = false,
            error = null
        )

        val result = repository.generateTextWithQwen("prompt")

        assertApiResponseError(result, "テキスト生成に失敗しました")
    }

    @Test
    fun generateTextWithGemini_returnsDefaultApiResponseError_whenResultIsMissing() = runTest {
        coEvery { apiService.generateTextWithGemini(any()) } returns TextGenerationResponse(
            success = true,
            result = null,
            error = null
        )

        val result = repository.generateTextWithGemini("prompt")

        assertApiResponseError(result, "テキスト生成に失敗しました")
    }

    @Test
    fun geocode_returnsPlaces_whenResponseHasPlaces() = runTest {
        val places = listOf(
            GeocodedPlace(
                inputAddress = "a",
                formattedAddress = "a formatted",
                location = LatLng(latitude = 35.0, longitude = 139.0)
            )
        )
        coEvery { apiService.geocode(any()) } returns GeocodeResponse(
            success = true,
            places = places
        )

        val result = repository.geocode(listOf("a"))

        assertEquals(ApiResult.Success(places), result)
    }

    @Test
    fun geocode_returnsDefaultApiResponseError_whenPlacesMissing() = runTest {
        coEvery { apiService.geocode(any()) } returns GeocodeResponse(
            success = true,
            places = null,
            error = null
        )

        val result = repository.geocode(listOf("a"))

        assertApiResponseError(result, "ジオコーディングに失敗しました")
    }

    @Test
    fun optimizeRoute_buildsRequestWithDefaults_andReturnsResponseOnSuccess() = runTest {
        val origin = RouteWaypoint(address = "origin")
        val destination = RouteWaypoint(address = "destination")
        val requestSlot = slot<com.fumiyakume.viewer.data.network.RouteOptimizeRequest>()
        val response = RouteOptimizeResponse(success = true)
        coEvery { apiService.optimizeRoute(capture(requestSlot)) } returns response

        val result = repository.optimizeRoute(origin = origin, destination = destination)

        assertEquals(ApiResult.Success(response), result)
        assertEquals(origin, requestSlot.captured.origin)
        assertEquals(destination, requestSlot.captured.destination)
        assertEquals(emptyList<RouteWaypoint>(), requestSlot.captured.intermediates)
        assertEquals("DRIVE", requestSlot.captured.travelMode)
        assertTrue(requestSlot.captured.optimizeWaypointOrder)
    }

    @Test
    fun optimizeRoute_returnsDefaultApiResponseError_onFailure() = runTest {
        coEvery { apiService.optimizeRoute(any()) } returns RouteOptimizeResponse(
            success = false,
            error = null
        )

        val result = repository.optimizeRoute(
            origin = RouteWaypoint(address = "origin"),
            destination = RouteWaypoint(address = "destination")
        )

        assertApiResponseError(result, "ルート最適化に失敗しました")
    }

    @Test
    fun optimizeRoute_returnsApiResponseError_withProvidedErrorMessage_onFailure() = runTest {
        coEvery { apiService.optimizeRoute(any()) } returns RouteOptimizeResponse(
            success = false,
            error = "detail"
        )

        val result = repository.optimizeRoute(
            origin = RouteWaypoint(address = "origin"),
            destination = RouteWaypoint(address = "destination")
        )

        assertApiResponseError(result, "detail")
    }

    @Test
    fun runPipeline_buildsRequestWithDefaults_andReturnsResponseOnSuccess() = runTest {
        val requestSlot = slot<com.fumiyakume.viewer.data.network.PipelineRequest>()
        val response = PipelineResponse(success = true)
        coEvery { apiService.runPipeline(capture(requestSlot)) } returns response

        val result = repository.runPipeline(
            startPoint = "start",
            purpose = "purpose",
            spotCount = 3
        )

        assertEquals(ApiResult.Success(response), result)
        assertEquals("start", requestSlot.captured.startPoint)
        assertEquals("purpose", requestSlot.captured.purpose)
        assertEquals(3, requestSlot.captured.spotCount)
        assertEquals("gemini", requestSlot.captured.model)
    }

    @Test
    fun runPipeline_returnsDefaultApiResponseError_onFailure() = runTest {
        coEvery { apiService.runPipeline(any()) } returns PipelineResponse(
            success = false,
            error = null
        )

        val result = repository.runPipeline(
            startPoint = "start",
            purpose = "purpose",
            spotCount = 3
        )

        assertApiResponseError(result, "パイプライン実行に失敗しました")
    }

    @Test
    fun generateRoute_buildsNestedRequest_andReturnsResponseOnSuccess() = runTest {
        val requestSlot = slot<com.fumiyakume.viewer.data.network.RouteGenerateRequest>()
        val response = RouteGenerationResponse(success = true)
        coEvery { apiService.generateRoute(capture(requestSlot)) } returns response

        val result = repository.generateRoute(
            startPoint = "start",
            purpose = "purpose",
            spotCount = 2,
            model = "qwen"
        )

        assertEquals(ApiResult.Success(response), result)
        assertEquals(
            RouteGenerateInput(
                startPoint = "start",
                purpose = "purpose",
                spotCount = 2,
                model = "qwen"
            ),
            requestSlot.captured.input
        )
    }

    @Test
    fun generateRoute_returnsDefaultApiResponseError_onFailure() = runTest {
        coEvery { apiService.generateRoute(any()) } returns RouteGenerationResponse(
            success = false,
            error = null
        )

        val result = repository.generateRoute(
            startPoint = "start",
            purpose = "purpose",
            spotCount = 2
        )

        assertApiResponseError(result, "ルート生成に失敗しました")
    }

    @Test
    fun generateScenario_buildsRequest_andReturnsResponseOnSuccess() = runTest {
        val requestSlot = slot<ScenarioRequest>()
        val response = ScenarioOutput(success = true)
        coEvery { apiService.generateScenario(capture(requestSlot)) } returns response

        val spots = listOf(
            RouteSpot(name = "spot", type = "type", description = "desc", point = "point")
        )
        val result = repository.generateScenario(
            routeName = "route",
            spots = spots,
            language = "ja",
            models = "both"
        )

        assertEquals(ApiResult.Success(response), result)
        assertEquals(
            ScenarioRequest(
                route = ScenarioRoute(routeName = "route", spots = spots, language = "ja"),
                models = "both"
            ),
            requestSlot.captured
        )
    }

    @Test
    fun generateScenario_returnsDefaultApiResponseError_onFailure() = runTest {
        coEvery { apiService.generateScenario(any()) } returns ScenarioOutput(
            success = false,
            error = null
        )

        val result = repository.generateScenario(
            routeName = "route",
            spots = emptyList()
        )

        assertApiResponseError(result, "シナリオ生成に失敗しました")
    }

    @Test
    fun generateScenario_returnsApiResponseError_withProvidedErrorMessage_onFailure() = runTest {
        coEvery { apiService.generateScenario(any()) } returns ScenarioOutput(
            success = false,
            error = "detail"
        )

        val result = repository.generateScenario(
            routeName = "route",
            spots = emptyList()
        )

        assertApiResponseError(result, "detail")
    }

    @Test
    fun generateSpotScenario_buildsRequest_andReturnsResponseOnSuccess() = runTest {
        val requestSlot = slot<com.fumiyakume.viewer.data.network.SpotScenarioRequest>()
        val response = SpotScenarioResponse(success = true)
        coEvery { apiService.generateSpotScenario(capture(requestSlot)) } returns response

        val result = repository.generateSpotScenario(
            routeName = "route",
            spotName = "spot",
            description = "desc",
            point = "point",
            models = "gemini"
        )

        assertEquals(ApiResult.Success(response), result)
        assertEquals("route", requestSlot.captured.routeName)
        assertEquals("spot", requestSlot.captured.spotName)
        assertEquals("desc", requestSlot.captured.description)
        assertEquals("point", requestSlot.captured.point)
        assertEquals("gemini", requestSlot.captured.models)
    }

    @Test
    fun generateSpotScenario_returnsDefaultApiResponseError_onFailure() = runTest {
        coEvery { apiService.generateSpotScenario(any()) } returns SpotScenarioResponse(
            success = false,
            error = null
        )

        val result = repository.generateSpotScenario(
            routeName = "route",
            spotName = "spot"
        )

        assertApiResponseError(result, "スポットシナリオ生成に失敗しました")
    }

    @Test
    fun integrateScenario_buildsRequest_andReturnsResponseOnSuccess() = runTest {
        val requestSlot = slot<com.fumiyakume.viewer.data.network.ScenarioIntegrateRequest>()
        val response = ScenarioIntegrationOutput(success = true)
        coEvery { apiService.integrateScenario(capture(requestSlot)) } returns response

        val scenarios = listOf(SpotScenario(spotName = "spot", scenario = "text"))
        val result = repository.integrateScenario(scenarios)

        assertEquals(ApiResult.Success(response), result)
        assertEquals(scenarios, requestSlot.captured.scenarios)
    }

    @Test
    fun integrateScenario_returnsDefaultApiResponseError_onFailure() = runTest {
        coEvery { apiService.integrateScenario(any()) } returns ScenarioIntegrationOutput(
            success = false,
            error = null
        )

        val result = repository.integrateScenario(emptyList())

        assertApiResponseError(result, "シナリオ統合に失敗しました")
    }

    private fun <T> assertApiResponseError(result: ApiResult<T>, expectedMessage: String) {
        assertTrue(result is ApiResult.Error)
        assertEquals(ApiError.ApiResponseError(expectedMessage), (result as ApiResult.Error).error)
    }
}
