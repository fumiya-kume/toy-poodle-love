package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performScrollToIndex
import com.fumiyakume.viewer.data.network.GeneratedSpot
import com.fumiyakume.viewer.data.network.PipelineResponse
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class PipelineTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun pipelineTab_showsEmptyResultState() {
        val uiState = ScenarioWriterUiState(
            pipelineStartPoint = "東京駅",
            pipelinePurpose = "皇居周辺の観光スポット",
            pipelineModel = AIModel.GEMINI
        )

        composeRule.setContent {
            TeslaTheme {
                PipelineTab(
                    uiState = uiState,
                    onStartPointChange = {},
                    onPurposeChange = {},
                    onSpotCountChange = {},
                    onModelChange = {},
                    onRunPipeline = {},
                    onShowOnMap = {},
                    onGenerateScenario = {}
                )
            }
        }

        composeRule.onAllNodesWithText("入力", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("パイプライン実行", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onNodeWithTag("pipeline_list").performScrollToIndex(1)
        composeRule.onAllNodesWithText("結果", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果がありません", useUnmergedTree = true).assertCountEquals(1)
    }

    @Test
    fun pipelineTab_showsResultDetails() {
        val result = PipelineResponse(
            success = true,
            routeName = "皇居ルート",
            spots = listOf(
                GeneratedSpot(
                    name = "東京駅",
                    type = "start",
                    description = "集合地点"
                )
            ),
            totalDistanceKm = 12.3,
            totalDurationMinutes = 45,
            processingTimeMs = 1200
        )
        val uiState = ScenarioWriterUiState(
            pipelineStartPoint = "東京駅",
            pipelinePurpose = "皇居周辺の観光スポット",
            pipelineModel = AIModel.GEMINI,
            pipelineResult = result
        )

        composeRule.setContent {
            TeslaTheme {
                PipelineTab(
                    uiState = uiState,
                    onStartPointChange = {},
                    onPurposeChange = {},
                    onSpotCountChange = {},
                    onModelChange = {},
                    onRunPipeline = {},
                    onShowOnMap = {},
                    onGenerateScenario = {}
                )
            }
        }

        composeRule.onNodeWithTag("pipeline_list").performScrollToIndex(1)
        composeRule.onAllNodesWithText("生成されたスポット", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("1. 東京駅", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("総距離: 12.3 km", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("所要時間: 45 分", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("処理時間: 1200 ms", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("マップで表示", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("シナリオを生成", useUnmergedTree = true).assertCountEquals(1)
    }
}
