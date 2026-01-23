package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.fumiyakume.viewer.data.network.ScenarioOutput
import com.fumiyakume.viewer.data.network.SpotScenarioResult
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ScenarioIntegrateTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun scenarioIntegrateTab_showsEmptyState() {
        val uiState = ScenarioWriterUiState()

        composeRule.setContent {
            TeslaTheme {
                ScenarioIntegrateTab(
                    uiState = uiState,
                    onIntegrate = {},
                    onGoToScenarioGenerate = {}
                )
            }
        }

        composeRule.onNodeWithText(
            "統合するシナリオがありません。まずシナリオ生成タブでシナリオを生成してください。",
            useUnmergedTree = true
        ).assertIsDisplayed()
        composeRule.onNodeWithText("シナリオ生成タブへ", useUnmergedTree = true).assertIsDisplayed()
    }

    @Test
    fun scenarioIntegrateTab_showsReadyState() {
        val scenarioResult = ScenarioOutput(
            success = true,
            spotScenarios = listOf(
                SpotScenarioResult(
                    spotName = "東京駅",
                    spotType = "start",
                    scenario = "集合"
                )
            )
        )
        val uiState = ScenarioWriterUiState(
            scenarioResult = scenarioResult
        )

        composeRule.setContent {
            TeslaTheme {
                ScenarioIntegrateTab(
                    uiState = uiState,
                    onIntegrate = {},
                    onGoToScenarioGenerate = {}
                )
            }
        }

        composeRule.onNodeWithText("シナリオ統合", useUnmergedTree = true).assertIsDisplayed()
        composeRule.onNodeWithText("以下のシナリオを統合します", useUnmergedTree = true).assertIsDisplayed()
        composeRule.onNodeWithText("• 東京駅", useUnmergedTree = true).assertIsDisplayed()
        composeRule.onNodeWithText("シナリオを統合", useUnmergedTree = true).assertIsDisplayed()
    }
}
