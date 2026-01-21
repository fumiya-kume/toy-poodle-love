package com.fumiyakume.viewer.data.repository

import com.fumiyakume.viewer.data.network.ApiError
import com.fumiyakume.viewer.data.network.ApiResult
import com.fumiyakume.viewer.data.network.ApiService
import com.fumiyakume.viewer.data.network.GeocodeRequest
import com.fumiyakume.viewer.data.network.GeocodeResponse
import com.fumiyakume.viewer.data.network.GeocodedPlace
import com.fumiyakume.viewer.data.network.PipelineRequest
import com.fumiyakume.viewer.data.network.PipelineResponse
import com.fumiyakume.viewer.data.network.RouteGenerateInput
import com.fumiyakume.viewer.data.network.RouteGenerateRequest
import com.fumiyakume.viewer.data.network.RouteGenerationResponse
import com.fumiyakume.viewer.data.network.RouteOptimizeRequest
import com.fumiyakume.viewer.data.network.RouteOptimizeResponse
import com.fumiyakume.viewer.data.network.RouteSpot
import com.fumiyakume.viewer.data.network.RouteWaypoint
import com.fumiyakume.viewer.data.network.ScenarioIntegrateRequest
import com.fumiyakume.viewer.data.network.ScenarioIntegrationOutput
import com.fumiyakume.viewer.data.network.ScenarioOutput
import com.fumiyakume.viewer.data.network.ScenarioRequest
import com.fumiyakume.viewer.data.network.ScenarioRoute
import com.fumiyakume.viewer.data.network.SpotScenario
import com.fumiyakume.viewer.data.network.SpotScenarioRequest
import com.fumiyakume.viewer.data.network.SpotScenarioResponse
import com.fumiyakume.viewer.data.network.TextGenerationRequest
import com.fumiyakume.viewer.data.network.TextGenerationResponse
import com.fumiyakume.viewer.data.network.safeApiCall
import javax.inject.Inject
import javax.inject.Singleton

/**
 * シナリオ関連のAPI呼び出しを管理するリポジトリ
 *
 * macOS版と同じAPIエンドポイントを使用
 */
@Singleton
class ScenarioRepository @Inject constructor(
    private val apiService: ApiService
) {
    // region Text Generation

    /**
     * Qwen AIでテキスト生成
     */
    suspend fun generateTextWithQwen(message: String): ApiResult<String> {
        return safeApiCall {
            val response = apiService.generateTextWithQwen(TextGenerationRequest(message))
            if (response.success && response.result != null) {
                response.result
            } else {
                throw ApiError.ApiResponseError(response.error ?: "テキスト生成に失敗しました")
            }
        }
    }

    /**
     * Gemini AIでテキスト生成
     */
    suspend fun generateTextWithGemini(message: String): ApiResult<String> {
        return safeApiCall {
            val response = apiService.generateTextWithGemini(TextGenerationRequest(message))
            if (response.success && response.result != null) {
                response.result
            } else {
                throw ApiError.ApiResponseError(response.error ?: "テキスト生成に失敗しました")
            }
        }
    }

    // endregion

    // region Places

    /**
     * 住所からジオコーディング
     */
    suspend fun geocode(addresses: List<String>): ApiResult<List<GeocodedPlace>> {
        return safeApiCall {
            val response = apiService.geocode(GeocodeRequest(addresses))
            if (response.success && response.places != null) {
                response.places
            } else {
                throw ApiError.ApiResponseError(response.error ?: "ジオコーディングに失敗しました")
            }
        }
    }

    // endregion

    // region Routes

    /**
     * ルート最適化
     */
    suspend fun optimizeRoute(
        origin: RouteWaypoint,
        destination: RouteWaypoint,
        intermediates: List<RouteWaypoint> = emptyList(),
        travelMode: String = "DRIVE",
        optimizeWaypointOrder: Boolean = true
    ): ApiResult<RouteOptimizeResponse> {
        return safeApiCall {
            val request = RouteOptimizeRequest(
                origin = origin,
                destination = destination,
                intermediates = intermediates,
                travelMode = travelMode,
                optimizeWaypointOrder = optimizeWaypointOrder
            )
            val response = apiService.optimizeRoute(request)
            if (response.success) {
                response
            } else {
                throw ApiError.ApiResponseError(response.error ?: "ルート最適化に失敗しました")
            }
        }
    }

    // endregion

    // region Pipeline

    /**
     * E2Eパイプライン実行
     */
    suspend fun runPipeline(
        startPoint: String,
        purpose: String,
        spotCount: Int,
        model: String = "gemini"
    ): ApiResult<PipelineResponse> {
        return safeApiCall {
            val request = PipelineRequest(
                startPoint = startPoint,
                purpose = purpose,
                spotCount = spotCount,
                model = model
            )
            val response = apiService.runPipeline(request)
            if (response.success) {
                response
            } else {
                throw ApiError.ApiResponseError(response.error ?: "パイプライン実行に失敗しました")
            }
        }
    }

    // endregion

    // region Scenario Generation

    /**
     * ルート生成
     */
    suspend fun generateRoute(
        startPoint: String,
        purpose: String,
        spotCount: Int,
        model: String = "gemini"
    ): ApiResult<RouteGenerationResponse> {
        return safeApiCall {
            val request = RouteGenerateRequest(
                input = RouteGenerateInput(
                    startPoint = startPoint,
                    purpose = purpose,
                    spotCount = spotCount,
                    model = model
                )
            )
            val response = apiService.generateRoute(request)
            if (response.success) {
                response
            } else {
                throw ApiError.ApiResponseError(response.error ?: "ルート生成に失敗しました")
            }
        }
    }

    /**
     * シナリオ生成
     */
    suspend fun generateScenario(
        routeName: String,
        spots: List<RouteSpot>,
        language: String? = null,
        models: String = "both"
    ): ApiResult<ScenarioOutput> {
        return safeApiCall {
            val request = ScenarioRequest(
                route = ScenarioRoute(
                    routeName = routeName,
                    spots = spots,
                    language = language
                ),
                models = models
            )
            val response = apiService.generateScenario(request)
            if (response.success) {
                response
            } else {
                throw ApiError.ApiResponseError(response.error ?: "シナリオ生成に失敗しました")
            }
        }
    }

    /**
     * スポットシナリオ生成
     */
    suspend fun generateSpotScenario(
        routeName: String,
        spotName: String,
        description: String? = null,
        point: String? = null,
        models: String = "gemini"
    ): ApiResult<SpotScenarioResponse> {
        return safeApiCall {
            val request = SpotScenarioRequest(
                routeName = routeName,
                spotName = spotName,
                description = description,
                point = point,
                models = models
            )
            val response = apiService.generateSpotScenario(request)
            if (response.success) {
                response
            } else {
                throw ApiError.ApiResponseError(response.error ?: "スポットシナリオ生成に失敗しました")
            }
        }
    }

    /**
     * シナリオ統合
     */
    suspend fun integrateScenario(
        scenarios: List<SpotScenario>
    ): ApiResult<ScenarioIntegrationOutput> {
        return safeApiCall {
            val request = ScenarioIntegrateRequest(scenarios = scenarios)
            val response = apiService.integrateScenario(request)
            if (response.success) {
                response
            } else {
                throw ApiError.ApiResponseError(response.error ?: "シナリオ統合に失敗しました")
            }
        }
    }

    // endregion
}
