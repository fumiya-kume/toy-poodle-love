package com.fumiyakume.viewer.ui.scenariowriter

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.NavigationRailItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.fumiyakume.viewer.ui.components.molecules.TeslaLoadingOverlay
import com.fumiyakume.viewer.ui.scenariowriter.tabs.GeocodeTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.PipelineTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.RouteGenerateTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.RouteOptimizeTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.ScenarioGenerateTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.ScenarioIntegrateTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.ScenarioMapTab
import com.fumiyakume.viewer.ui.scenariowriter.tabs.TextGenerationTab
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * シナリオライター画面
 *
 * NavigationRail（左サイドバー）で8つのタブを切り替え
 * タブレット向けレイアウト
 */
@Composable
fun ScenarioWriterScreen(
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ScenarioWriterViewModel = hiltViewModel()
) {
    val selectedTab by viewModel.selectedTab.collectAsState()
    val uiState by viewModel.uiState.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }

    // エラー表示
    LaunchedEffect(errorMessage) {
        errorMessage?.let { message ->
            snackbarHostState.showSnackbar(
                message = message,
                duration = SnackbarDuration.Short
            )
            viewModel.clearError()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = TeslaColors.Background,
        modifier = modifier
    ) { paddingValues ->
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Navigation Rail
            ScenarioWriterNavigationRail(
                selectedTab = selectedTab,
                onTabSelected = { viewModel.selectTab(it) },
                onNavigateBack = onNavigateBack
            )

            // コンテンツエリア
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxSize()
                    .background(TeslaColors.Background)
            ) {
                // タブコンテンツ
                when (selectedTab) {
                    ScenarioWriterTab.PIPELINE -> PipelineTab(
                        uiState = uiState,
                        onStartPointChange = viewModel::updatePipelineStartPoint,
                        onPurposeChange = viewModel::updatePipelinePurpose,
                        onSpotCountChange = viewModel::updatePipelineSpotCount,
                        onModelChange = viewModel::updatePipelineModel,
                        onRunPipeline = viewModel::runPipeline,
                        onShowOnMap = viewModel::createMapSpotsFromPipeline,
                        onGenerateScenario = viewModel::createSpotsFromPipeline
                    )

                    ScenarioWriterTab.ROUTE_GENERATE -> RouteGenerateTab(
                        uiState = uiState,
                        onStartPointChange = viewModel::updateRouteGenerateStartPoint,
                        onPurposeChange = viewModel::updateRouteGeneratePurpose,
                        onSpotCountChange = viewModel::updateRouteGenerateSpotCount,
                        onModelChange = viewModel::updateRouteGenerateModel,
                        onGenerateRoute = viewModel::generateRoute,
                        onGoToScenario = viewModel::createSpotsFromRouteGeneration
                    )

                    ScenarioWriterTab.SCENARIO_GENERATE -> ScenarioGenerateTab(
                        uiState = uiState,
                        onRouteNameChange = viewModel::updateScenarioRouteName,
                        onLanguageChange = viewModel::updateScenarioLanguage,
                        onModelsChange = viewModel::updateScenarioModels,
                        onAddSpot = viewModel::addScenarioSpot,
                        onRemoveSpot = viewModel::removeScenarioSpot,
                        onGenerateScenario = viewModel::generateScenario,
                        onIntegrate = { viewModel.selectTab(ScenarioWriterTab.SCENARIO_INTEGRATE) }
                    )

                    ScenarioWriterTab.SCENARIO_INTEGRATE -> ScenarioIntegrateTab(
                        uiState = uiState,
                        onIntegrate = viewModel::integrateScenarios,
                        onGoToScenarioGenerate = { viewModel.selectTab(ScenarioWriterTab.SCENARIO_GENERATE) }
                    )

                    ScenarioWriterTab.SCENARIO_MAP -> ScenarioMapTab(
                        uiState = uiState,
                        onSpotSelected = viewModel::selectMapSpot,
                        onGoToPipeline = { viewModel.selectTab(ScenarioWriterTab.PIPELINE) }
                    )

                    ScenarioWriterTab.TEXT_GENERATION -> TextGenerationTab(
                        uiState = uiState,
                        onPromptChange = viewModel::updateTextGenerationPrompt,
                        onModelChange = viewModel::updateTextGenerationModel,
                        onGenerate = viewModel::generateText
                    )

                    ScenarioWriterTab.GEOCODE -> GeocodeTab(
                        uiState = uiState,
                        onAddressesChange = viewModel::updateGeocodeAddresses,
                        onGeocode = viewModel::geocode
                    )

                    ScenarioWriterTab.ROUTE_OPTIMIZE -> RouteOptimizeTab(
                        uiState = uiState,
                        onWaypointInputChange = viewModel::updateWaypointInput,
                        onAddWaypoint = viewModel::addWaypoint,
                        onRemoveWaypoint = viewModel::removeWaypoint,
                        onTravelModeChange = viewModel::updateTravelMode,
                        onOptimizeOrderChange = viewModel::updateOptimizeWaypointOrder,
                        onOptimizeRoute = viewModel::optimizeRoute
                    )
                }

                // Loading overlay on top of content
                TeslaLoadingOverlay(
                    isLoading = uiState.isLoading,
                    message = getLoadingMessage(selectedTab)
                )
            }
        }
    }
}

@Composable
private fun ScenarioWriterNavigationRail(
    selectedTab: ScenarioWriterTab,
    onTabSelected: (ScenarioWriterTab) -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    NavigationRail(
        containerColor = TeslaColors.Surface,
        contentColor = TeslaColors.TextPrimary,
        modifier = modifier,
        header = {
            // 戻るボタン
            NavigationRailItem(
                selected = false,
                onClick = onNavigateBack,
                icon = {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "戻る"
                    )
                },
                colors = NavigationRailItemDefaults.colors(
                    unselectedIconColor = TeslaColors.TextSecondary,
                    unselectedTextColor = TeslaColors.TextSecondary
                )
            )
        }
    ) {
        ScenarioWriterTab.entries.forEach { tab ->
            NavigationRailItem(
                selected = selectedTab == tab,
                onClick = { onTabSelected(tab) },
                icon = {
                    Icon(
                        imageVector = tab.icon,
                        contentDescription = tab.label
                    )
                },
                label = {
                    Text(
                        text = tab.label,
                        style = TeslaTheme.typography.labelSmall,
                        maxLines = 1
                    )
                },
                colors = NavigationRailItemDefaults.colors(
                    selectedIconColor = TeslaColors.Accent,
                    selectedTextColor = TeslaColors.Accent,
                    indicatorColor = TeslaColors.Accent.copy(alpha = 0.12f),
                    unselectedIconColor = TeslaColors.TextSecondary,
                    unselectedTextColor = TeslaColors.TextSecondary
                )
            )
        }
    }
}

private fun getLoadingMessage(tab: ScenarioWriterTab): String {
    return when (tab) {
        ScenarioWriterTab.PIPELINE -> "パイプライン実行中..."
        ScenarioWriterTab.ROUTE_GENERATE -> "ルート生成中..."
        ScenarioWriterTab.SCENARIO_GENERATE -> "シナリオ生成中..."
        ScenarioWriterTab.SCENARIO_INTEGRATE -> "シナリオ統合中..."
        ScenarioWriterTab.SCENARIO_MAP -> "マップ読み込み中..."
        ScenarioWriterTab.TEXT_GENERATION -> "テキスト生成中..."
        ScenarioWriterTab.GEOCODE -> "ジオコーディング中..."
        ScenarioWriterTab.ROUTE_OPTIMIZE -> "ルート最適化中..."
    }
}

@Preview(
    showBackground = true,
    widthDp = 1024,
    heightDp = 768
)
@Composable
private fun ScenarioWriterScreenPreview() {
    TeslaTheme {
        // Preview用のモックUI
        Row(
            modifier = Modifier
                .fillMaxSize()
                .background(TeslaColors.Background)
        ) {
            NavigationRail(
                containerColor = TeslaColors.Surface,
                modifier = Modifier.padding(vertical = 8.dp)
            ) {
                ScenarioWriterTab.entries.take(4).forEach { tab ->
                    NavigationRailItem(
                        selected = tab == ScenarioWriterTab.PIPELINE,
                        onClick = {},
                        icon = {
                            Icon(
                                imageVector = tab.icon,
                                contentDescription = tab.label,
                                tint = if (tab == ScenarioWriterTab.PIPELINE) TeslaColors.Accent else TeslaColors.TextSecondary
                            )
                        },
                        label = {
                            Text(
                                text = tab.label,
                                color = if (tab == ScenarioWriterTab.PIPELINE) TeslaColors.Accent else TeslaColors.TextSecondary
                            )
                        }
                    )
                }
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxSize()
                    .padding(24.dp)
            ) {
                Text(
                    text = "Pipeline Tab Content",
                    color = TeslaColors.TextPrimary
                )
            }
        }
    }
}
