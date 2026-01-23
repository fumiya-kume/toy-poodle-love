package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performScrollToIndex
import com.fumiyakume.viewer.data.network.RouteSpot
import com.fumiyakume.viewer.data.network.ScenarioOutput
import com.fumiyakume.viewer.data.network.SpotScenarioResult
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioModels
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ScenarioGenerateTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun scenarioGenerateTab_showsEmptyState() {
        val uiState = ScenarioWriterUiState(
            scenarioRouteName = "",
            scenarioLanguage = "",
            scenarioModels = ScenarioModels.BOTH
        )

        composeRule.setContent {
            TeslaTheme {
                ScenarioGenerateTab(
                    uiState = uiState,
                    onRouteNameChange = {},
                    onLanguageChange = {},
                    onModelsChange = {},
                    onAddSpot = {},
                    onRemoveSpot = {},
                    onGenerateScenario = {},
                    onIntegrate = {}
                )
            }
        }

        composeRule.onAllNodesWithText("入力", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("スポット追加", useUnmergedTree = true).assertCountEquals(1)

        composeRule.onNodeWithTag("scenario_generate_list").performScrollToIndex(2)
        composeRule.onAllNodesWithText("スポットリスト (0件)", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("スポットがありません", useUnmergedTree = true).assertCountEquals(1)

        composeRule.onNodeWithTag("scenario_generate_list").performScrollToIndex(3)
        composeRule.onAllNodesWithText("結果", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果がありません", useUnmergedTree = true).assertCountEquals(1)
    }

    @Test
    fun scenarioGenerateTab_showsResultAndIntegrateAction() {
        val scenarioResult = ScenarioOutput(
            success = true,
            routeName = "皇居ルート",
            successCount = 1,
            totalCount = 2,
            spotScenarios = listOf(
                SpotScenarioResult(
                    spotName = "東京駅",
                    spotType = "start",
                    scenario = "集合"
                )
            )
        )
        val uiState = ScenarioWriterUiState(
            scenarioRouteName = "皇居ルート",
            scenarioSpots = listOf(RouteSpot("東京駅", "start")),
            scenarioModels = ScenarioModels.BOTH,
            scenarioResult = scenarioResult
        )

        composeRule.setContent {
            TeslaTheme {
                ScenarioGenerateTab(
                    uiState = uiState,
                    onRouteNameChange = {},
                    onLanguageChange = {},
                    onModelsChange = {},
                    onAddSpot = {},
                    onRemoveSpot = {},
                    onGenerateScenario = {},
                    onIntegrate = {}
                )
            }
        }

        composeRule.onNodeWithTag("scenario_generate_list").performScrollToIndex(2)
        composeRule.onAllNodesWithText("スポットリスト (1件)", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("1. 東京駅", useUnmergedTree = true).assertCountEquals(1)

        composeRule.onNodeWithTag("scenario_generate_list").performScrollToIndex(3)
        composeRule.onAllNodesWithText("ルート: 皇居ルート", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("成功: 1/2", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("シナリオ統合へ", useUnmergedTree = true).assertCountEquals(1)
    }
}
