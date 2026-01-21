package com.fumiyakume.viewer.ui.scenariowriter

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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
import com.fumiyakume.viewer.data.network.SpotScenario
import com.fumiyakume.viewer.data.repository.ScenarioRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * シナリオライターの状態管理ViewModel
 *
 * 8つのタブの入力状態、ローディング状態、結果を管理
 */
@HiltViewModel
class ScenarioWriterViewModel @Inject constructor(
    private val repository: ScenarioRepository
) : ViewModel() {

    // ========== ナビゲーション ==========
    private val _selectedTab = MutableStateFlow(ScenarioWriterTab.PIPELINE)
    val selectedTab: StateFlow<ScenarioWriterTab> = _selectedTab.asStateFlow()

    // ========== UI状態 ==========
    private val _uiState = MutableStateFlow(ScenarioWriterUiState())
    val uiState: StateFlow<ScenarioWriterUiState> = _uiState.asStateFlow()

    // ========== エラー ==========
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    // ========== タブ切り替え ==========
    fun selectTab(tab: ScenarioWriterTab) {
        _selectedTab.value = tab
    }

    // ========== エラークリア ==========
    fun clearError() {
        _errorMessage.value = null
    }

    // ========== Pipeline機能 ==========
    fun updatePipelineStartPoint(value: String) {
        _uiState.update { it.copy(pipelineStartPoint = value) }
    }

    fun updatePipelinePurpose(value: String) {
        _uiState.update { it.copy(pipelinePurpose = value) }
    }

    fun updatePipelineSpotCount(value: Int) {
        _uiState.update { it.copy(pipelineSpotCount = value.coerceIn(3, 8)) }
    }

    fun updatePipelineModel(model: AIModel) {
        _uiState.update { it.copy(pipelineModel = model) }
    }

    fun runPipeline() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingPipeline = true) }

            val result = repository.runPipeline(
                startPoint = _uiState.value.pipelineStartPoint,
                purpose = _uiState.value.pipelinePurpose,
                spotCount = _uiState.value.pipelineSpotCount,
                model = _uiState.value.pipelineModel.value
            )

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingPipeline = false,
                        pipelineResult = result.data
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingPipeline = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== RouteGenerate機能 ==========
    fun updateRouteGenerateStartPoint(value: String) {
        _uiState.update { it.copy(routeGenerateStartPoint = value) }
    }

    fun updateRouteGeneratePurpose(value: String) {
        _uiState.update { it.copy(routeGeneratePurpose = value) }
    }

    fun updateRouteGenerateSpotCount(value: Int) {
        _uiState.update { it.copy(routeGenerateSpotCount = value.coerceIn(3, 8)) }
    }

    fun updateRouteGenerateModel(model: AIModel) {
        _uiState.update { it.copy(routeGenerateModel = model) }
    }

    fun generateRoute() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingRouteGenerate = true) }

            val result = repository.generateRoute(
                startPoint = _uiState.value.routeGenerateStartPoint,
                purpose = _uiState.value.routeGeneratePurpose,
                spotCount = _uiState.value.routeGenerateSpotCount,
                model = _uiState.value.routeGenerateModel.value
            )

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingRouteGenerate = false,
                        routeGenerateResult = result.data
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingRouteGenerate = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== Scenario生成機能 ==========
    fun updateScenarioRouteName(value: String) {
        _uiState.update { it.copy(scenarioRouteName = value) }
    }

    fun updateScenarioLanguage(value: String) {
        _uiState.update { it.copy(scenarioLanguage = value) }
    }

    fun updateScenarioModels(models: ScenarioModels) {
        _uiState.update { it.copy(scenarioModels = models) }
    }

    fun addScenarioSpot(spot: RouteSpot) {
        _uiState.update { it.copy(scenarioSpots = it.scenarioSpots + spot) }
    }

    fun removeScenarioSpot(index: Int) {
        _uiState.update {
            it.copy(scenarioSpots = it.scenarioSpots.filterIndexed { i, _ -> i != index })
        }
    }

    fun generateScenario() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingScenario = true) }

            val result = repository.generateScenario(
                routeName = _uiState.value.scenarioRouteName,
                spots = _uiState.value.scenarioSpots,
                language = _uiState.value.scenarioLanguage.takeIf { it.isNotBlank() },
                models = _uiState.value.scenarioModels.value
            )

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingScenario = false,
                        scenarioResult = result.data
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingScenario = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== Scenario統合機能 ==========
    fun integrateScenarios() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingScenarioIntegrate = true) }

            val scenarioResult = _uiState.value.scenarioResult
            if (scenarioResult?.spotScenarios == null) {
                _errorMessage.value = "統合するシナリオがありません"
                _uiState.update { it.copy(isLoadingScenarioIntegrate = false) }
                return@launch
            }

            val spotScenarios = scenarioResult.spotScenarios
                .filter { it.scenario != null }
                .map { SpotScenario(spotName = it.spotName, scenario = it.scenario!!) }

            val result = repository.integrateScenario(spotScenarios)

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingScenarioIntegrate = false,
                        scenarioIntegrationResult = result.data
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingScenarioIntegrate = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== TextGeneration機能 ==========
    fun updateTextGenerationPrompt(value: String) {
        _uiState.update { it.copy(textGenerationPrompt = value) }
    }

    fun updateTextGenerationModel(model: AIModel) {
        _uiState.update { it.copy(textGenerationModel = model) }
    }

    fun generateText() {
        viewModelScope.launch {
            // Snapshot model and prompt at start to prevent race conditions
            val snapshotModel = _uiState.value.textGenerationModel
            val snapshotPrompt = _uiState.value.textGenerationPrompt

            _uiState.update { it.copy(isLoadingTextGeneration = true) }

            val result = when (snapshotModel) {
                AIModel.GEMINI -> repository.generateTextWithGemini(snapshotPrompt)
                AIModel.QWEN -> repository.generateTextWithQwen(snapshotPrompt)
            }

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingTextGeneration = false,
                        textGenerationResult = result.data,
                        textGenerationResultModel = snapshotModel
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingTextGeneration = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== Geocode機能 ==========
    fun updateGeocodeAddresses(value: String) {
        _uiState.update { it.copy(geocodeAddresses = value) }
    }

    fun geocode() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingGeocode = true) }

            val addresses = _uiState.value.geocodeAddresses
                .split("\n")
                .map { it.trim() }
                .filter { it.isNotBlank() }

            if (addresses.isEmpty()) {
                _errorMessage.value = "住所を入力してください"
                _uiState.update { it.copy(isLoadingGeocode = false) }
                return@launch
            }

            val result = repository.geocode(addresses)

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingGeocode = false,
                        geocodeResult = result.data
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingGeocode = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== RouteOptimize機能 ==========
    fun updateTravelMode(mode: TravelMode) {
        _uiState.update { it.copy(travelMode = mode) }
    }

    fun updateOptimizeWaypointOrder(value: Boolean) {
        _uiState.update { it.copy(optimizeWaypointOrder = value) }
    }

    fun updateWaypointInput(value: String) {
        _uiState.update { it.copy(waypointInput = value) }
    }

    fun addWaypoint() {
        val address = _uiState.value.waypointInput.trim()
        if (address.isNotBlank()) {
            _uiState.update {
                it.copy(
                    routeWaypoints = it.routeWaypoints + RouteWaypoint(address = address),
                    waypointInput = ""
                )
            }
        }
    }

    fun removeWaypoint(index: Int) {
        _uiState.update {
            it.copy(routeWaypoints = it.routeWaypoints.filterIndexed { i, _ -> i != index })
        }
    }

    fun optimizeRoute() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingRouteOptimize = true) }

            val waypoints = _uiState.value.routeWaypoints
            if (waypoints.size < 2) {
                _errorMessage.value = "少なくとも2つのウェイポイントが必要です"
                _uiState.update { it.copy(isLoadingRouteOptimize = false) }
                return@launch
            }

            val result = repository.optimizeRoute(
                origin = waypoints.first(),
                destination = waypoints.last(),
                intermediates = if (waypoints.size > 2) waypoints.subList(1, waypoints.size - 1) else emptyList(),
                travelMode = _uiState.value.travelMode.value,
                optimizeWaypointOrder = _uiState.value.optimizeWaypointOrder
            )

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(
                        isLoadingRouteOptimize = false,
                        routeOptimizeResult = result.data
                    ) }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(isLoadingRouteOptimize = false) }
                    _errorMessage.value = result.error.message
                }
            }
        }
    }

    // ========== マップ機能 ==========
    fun updateMapSpots(spots: List<MapSpot>) {
        _uiState.update { it.copy(mapSpots = spots) }
    }

    fun selectMapSpot(spotId: String?) {
        _uiState.update { it.copy(selectedMapSpotId = spotId) }
    }

    fun createMapSpotsFromPipeline() {
        val pipelineResult = _uiState.value.pipelineResult ?: return
        val spots = pipelineResult.spots ?: return

        val mapSpots = spots.mapIndexed { index, spot ->
            MapSpot(
                id = "pipeline_$index",
                name = spot.name,
                type = spot.type,
                description = spot.description,
                address = null,
                coordinate = LatLng(35.681236, 139.767125) // デフォルト座標、実際はジオコーディング必要
            )
        }
        _uiState.update { it.copy(mapSpots = mapSpots) }
        _selectedTab.value = ScenarioWriterTab.SCENARIO_MAP
    }

    fun createSpotsFromPipeline() {
        val pipelineResult = _uiState.value.pipelineResult ?: return
        val spots = pipelineResult.spots ?: return

        val routeSpots = spots.mapIndexed { index, spot ->
            RouteSpot(
                name = spot.name,
                type = when (index) {
                    0 -> "start"
                    spots.size - 1 -> "destination"
                    else -> "waypoint"
                },
                description = spot.description
            )
        }
        _uiState.update {
            it.copy(
                scenarioRouteName = pipelineResult.routeName ?: "",
                scenarioSpots = routeSpots
            )
        }
        _selectedTab.value = ScenarioWriterTab.SCENARIO_GENERATE
    }

    fun createSpotsFromRouteGeneration() {
        val routeResult = _uiState.value.routeGenerateResult ?: return
        val spots = routeResult.spots ?: return

        val routeSpots = spots.mapIndexed { index, spot ->
            RouteSpot(
                name = spot.name,
                type = when (index) {
                    0 -> "start"
                    spots.size - 1 -> "destination"
                    else -> "waypoint"
                },
                description = spot.description
            )
        }
        _uiState.update { it.copy(scenarioSpots = routeSpots) }
        _selectedTab.value = ScenarioWriterTab.SCENARIO_GENERATE
    }
}

/**
 * シナリオライターのUI状態
 */
data class ScenarioWriterUiState(
    // Pipeline
    val pipelineStartPoint: String = "",
    val pipelinePurpose: String = "",
    val pipelineSpotCount: Int = 5,
    val pipelineModel: AIModel = AIModel.GEMINI,
    val isLoadingPipeline: Boolean = false,
    val pipelineResult: PipelineResponse? = null,

    // RouteGenerate
    val routeGenerateStartPoint: String = "",
    val routeGeneratePurpose: String = "",
    val routeGenerateSpotCount: Int = 5,
    val routeGenerateModel: AIModel = AIModel.GEMINI,
    val isLoadingRouteGenerate: Boolean = false,
    val routeGenerateResult: RouteGenerationResponse? = null,

    // Scenario
    val scenarioRouteName: String = "",
    val scenarioLanguage: String = "",
    val scenarioSpots: List<RouteSpot> = emptyList(),
    val scenarioModels: ScenarioModels = ScenarioModels.BOTH,
    val isLoadingScenario: Boolean = false,
    val scenarioResult: ScenarioOutput? = null,

    // ScenarioIntegrate
    val isLoadingScenarioIntegrate: Boolean = false,
    val scenarioIntegrationResult: ScenarioIntegrationOutput? = null,

    // TextGeneration
    val textGenerationPrompt: String = "",
    val textGenerationModel: AIModel = AIModel.GEMINI,
    val isLoadingTextGeneration: Boolean = false,
    val textGenerationResult: String? = null,
    val textGenerationResultModel: AIModel? = null,

    // Geocode
    val geocodeAddresses: String = "",
    val isLoadingGeocode: Boolean = false,
    val geocodeResult: List<GeocodedPlace>? = null,

    // RouteOptimize
    val routeWaypoints: List<RouteWaypoint> = emptyList(),
    val waypointInput: String = "",
    val travelMode: TravelMode = TravelMode.DRIVE,
    val optimizeWaypointOrder: Boolean = true,
    val isLoadingRouteOptimize: Boolean = false,
    val routeOptimizeResult: RouteOptimizeResponse? = null,

    // Map
    val mapSpots: List<MapSpot> = emptyList(),
    val selectedMapSpotId: String? = null
) {
    val canRunPipeline: Boolean
        get() = pipelineStartPoint.isNotBlank() && pipelinePurpose.isNotBlank()

    val canGenerateRoute: Boolean
        get() = routeGenerateStartPoint.isNotBlank() && routeGeneratePurpose.isNotBlank()

    val canGenerateScenario: Boolean
        get() = scenarioRouteName.isNotBlank() && scenarioSpots.isNotEmpty()

    val canIntegrateScenarios: Boolean
        get() = scenarioResult?.spotScenarios?.any { it.scenario != null } == true

    val canGenerateText: Boolean
        get() = textGenerationPrompt.isNotBlank()

    val canGeocode: Boolean
        get() = geocodeAddresses.isNotBlank()

    val canOptimizeRoute: Boolean
        get() = routeWaypoints.size >= 2

    val isLoading: Boolean
        get() = isLoadingPipeline || isLoadingRouteGenerate || isLoadingScenario ||
                isLoadingScenarioIntegrate || isLoadingTextGeneration || isLoadingGeocode ||
                isLoadingRouteOptimize
}

/**
 * マップ表示用スポット
 */
data class MapSpot(
    val id: String,
    val name: String,
    val type: String,
    val description: String?,
    val address: String?,
    val coordinate: LatLng
)
