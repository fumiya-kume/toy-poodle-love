package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ScenarioMapTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun scenarioMapTab_showsEmptyState() {
        val uiState = ScenarioWriterUiState()

        composeRule.setContent {
            TeslaTheme {
                ScenarioMapTab(
                    uiState = uiState,
                    onSpotSelected = {},
                    onGoToPipeline = {}
                )
            }
        }

        composeRule.onAllNodesWithText("マップに表示するデータがありません", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("Pipelineを実行して「マップで表示」をクリックしてください", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("Pipelineタブへ", useUnmergedTree = true).assertCountEquals(1)
    }
}
