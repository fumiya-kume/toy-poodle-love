package com.fumiyakume.viewer.data.network

import kotlinx.serialization.Serializable
import retrofit2.http.Body
import retrofit2.http.POST

/**
 * Taxi Scenario Writer API サービス
 *
 * macOS版と同じエンドポイントを使用
 * ベースURL: https://toy-poodle-lover.vercel.app
 */
interface ApiService {

    // AI生成
    @POST("api/qwen")
    suspend fun generateTextWithQwen(@Body request: TextGenerationRequest): TextGenerationResponse

    @POST("api/gemini")
    suspend fun generateTextWithGemini(@Body request: TextGenerationRequest): TextGenerationResponse

    // Places
    @POST("api/places/geocode")
    suspend fun geocode(@Body request: GeocodeRequest): GeocodeResponse

    // Routes
    @POST("api/routes/optimize")
    suspend fun optimizeRoute(@Body request: RouteOptimizeRequest): RouteOptimizeResponse

    // Pipeline
    @POST("api/pipeline/route-optimize")
    suspend fun runPipeline(@Body request: PipelineRequest): PipelineResponse

    // Scenario
    @POST("api/route/generate")
    suspend fun generateRoute(@Body request: RouteGenerateRequest): RouteGenerationResponse

    @POST("api/scenario")
    suspend fun generateScenario(@Body request: ScenarioRequest): ScenarioOutput

    @POST("api/scenario/spot")
    suspend fun generateSpotScenario(@Body request: SpotScenarioRequest): SpotScenarioResponse

    @POST("api/scenario/integrate")
    suspend fun integrateScenario(@Body request: ScenarioIntegrateRequest): ScenarioIntegrationOutput
}

// Request/Response models (基本的なもののみ、詳細は後で追加)

@Serializable
data class TextGenerationRequest(
    val message: String
)

@Serializable
data class TextGenerationResponse(
    val success: Boolean,
    val result: String? = null,
    val error: String? = null
)

@Serializable
data class GeocodeRequest(
    val addresses: List<String>
)

@Serializable
data class GeocodeResponse(
    val success: Boolean,
    val places: List<GeocodedPlace>? = null,
    val error: String? = null
)

@Serializable
data class GeocodedPlace(
    val inputAddress: String,
    val formattedAddress: String,
    val location: LatLng
)

@Serializable
data class LatLng(
    val latitude: Double,
    val longitude: Double
)

@Serializable
data class RouteOptimizeRequest(
    val origin: RouteWaypoint,
    val destination: RouteWaypoint,
    val intermediates: List<RouteWaypoint> = emptyList(),
    val travelMode: String = "DRIVE",
    val optimizeWaypointOrder: Boolean = true
)

@Serializable
data class RouteWaypoint(
    val address: String,
    val location: LatLng? = null
)

@Serializable
data class RouteOptimizeResponse(
    val success: Boolean,
    val optimizedOrder: List<String>? = null,
    val totalDistanceKm: Double? = null,
    val totalDurationMinutes: Int? = null,
    val error: String? = null
)

@Serializable
data class PipelineRequest(
    val startPoint: String,
    val purpose: String,
    val spotCount: Int,
    val model: String = "gemini"
)

@Serializable
data class PipelineResponse(
    val success: Boolean,
    val routeName: String? = null,
    val spots: List<GeneratedSpot>? = null,
    val optimizedOrder: List<String>? = null,
    val totalDistanceKm: Double? = null,
    val totalDurationMinutes: Int? = null,
    val processingTimeMs: Long? = null,
    val error: String? = null
)

@Serializable
data class GeneratedSpot(
    val name: String,
    val type: String,
    val description: String,
    val note: String? = null
)

@Serializable
data class RouteGenerateRequest(
    val input: RouteGenerateInput
)

@Serializable
data class RouteGenerateInput(
    val startPoint: String,
    val purpose: String,
    val spotCount: Int,
    val model: String = "gemini"
)

@Serializable
data class RouteGenerationResponse(
    val success: Boolean,
    val model: String? = null,
    val spots: List<GeneratedSpot>? = null,
    val error: String? = null
)

@Serializable
data class ScenarioRequest(
    val route: ScenarioRoute,
    val models: String = "both"
)

@Serializable
data class ScenarioRoute(
    val routeName: String,
    val spots: List<RouteSpot>,
    val language: String? = null
)

@Serializable
data class RouteSpot(
    val name: String,
    val type: String,
    val description: String? = null,
    val point: String? = null
)

@Serializable
data class ScenarioOutput(
    val success: Boolean,
    val routeName: String? = null,
    val generatedAt: String? = null,
    val successCount: Int? = null,
    val totalCount: Int? = null,
    val processingTimeMs: Long? = null,
    val spotScenarios: List<SpotScenarioResult>? = null,
    val error: String? = null
)

@Serializable
data class SpotScenarioResult(
    val spotName: String,
    val spotType: String,
    val scenario: String? = null,
    val error: String? = null
)

@Serializable
data class SpotScenarioRequest(
    val routeName: String,
    val spotName: String,
    val description: String? = null,
    val point: String? = null,
    val models: String = "gemini"
)

@Serializable
data class SpotScenarioResponse(
    val success: Boolean,
    val error: String? = null
)

@Serializable
data class ScenarioIntegrateRequest(
    val scenarios: List<SpotScenario>
)

@Serializable
data class SpotScenario(
    val spotName: String,
    val scenario: String
)

@Serializable
data class ScenarioIntegrationOutput(
    val success: Boolean,
    val routeName: String? = null,
    val integratedAt: String? = null,
    val usedModel: String? = null,
    val integrationLLM: String? = null,
    val processingTimeMs: Long? = null,
    val integratedScript: String? = null,
    val error: String? = null
)
