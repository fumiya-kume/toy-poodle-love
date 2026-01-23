package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performScrollToIndex
import com.fumiyakume.viewer.data.network.GeneratedSpot
import com.fumiyakume.viewer.data.network.RouteGenerationResponse
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RouteGenerateTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun routeGenerateTab_showsEmptyResultState() {
        val uiState = ScenarioWriterUiState(
            routeGenerateStartPoint = "東京駅",
            routeGeneratePurpose = "皇居周辺の観光スポット",
            routeGenerateModel = AIModel.GEMINI
        )

        composeRule.setContent {
            TeslaTheme {
                RouteGenerateTab(
                    uiState = uiState,
                    onStartPointChange = {},
                    onPurposeChange = {},
                    onSpotCountChange = {},
                    onModelChange = {},
                    onGenerateRoute = {},
                    onGoToScenario = {}
                )
            }
        }

        composeRule.onAllNodesWithText("入力", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("AIでルート生成", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onNodeWithTag("route_generate_list").performScrollToIndex(1)
        composeRule.onAllNodesWithText("結果", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果がありません", useUnmergedTree = true).assertCountEquals(1)
    }

    @Test
    fun routeGenerateTab_showsResultDetails() {
        val result = RouteGenerationResponse(
            success = true,
            model = "gemini",
            spots = listOf(
                GeneratedSpot(
                    name = "東京駅",
                    type = "start",
                    description = "集合地点"
                )
            )
        )
        val uiState = ScenarioWriterUiState(
            routeGenerateStartPoint = "東京駅",
            routeGeneratePurpose = "皇居周辺の観光スポット",
            routeGenerateModel = AIModel.GEMINI,
            routeGenerateResult = result
        )

        composeRule.setContent {
            TeslaTheme {
                RouteGenerateTab(
                    uiState = uiState,
                    onStartPointChange = {},
                    onPurposeChange = {},
                    onSpotCountChange = {},
                    onModelChange = {},
                    onGenerateRoute = {},
                    onGoToScenario = {}
                )
            }
        }

        composeRule.onNodeWithTag("route_generate_list").performScrollToIndex(1)
        composeRule.onAllNodesWithText("生成されたスポット", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("生成モデル: gemini", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("1. 東京駅", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("タイプ: start", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("シナリオ生成へ", useUnmergedTree = true).assertCountEquals(1)
    }
}
