package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class TextGenerationTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun textGenerationTab_showsEmptyResultState() {
        val uiState = ScenarioWriterUiState(
            textGenerationPrompt = "こんにちは",
            textGenerationModel = AIModel.GEMINI
        )

        composeRule.setContent {
            TeslaTheme {
                TextGenerationTab(
                    uiState = uiState,
                    onPromptChange = {},
                    onModelChange = {},
                    onGenerate = {}
                )
            }
        }

        composeRule.onAllNodesWithText("入力", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果がありません", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("生成", useUnmergedTree = true).assertCountEquals(1)
    }

    @Test
    fun textGenerationTab_showsResultAndModelLabel() {
        val uiState = ScenarioWriterUiState(
            textGenerationPrompt = "prompt",
            textGenerationModel = AIModel.QWEN,
            textGenerationResult = "出力テキスト",
            textGenerationResultModel = AIModel.QWEN,
            isLoadingTextGeneration = true
        )

        composeRule.setContent {
            TeslaTheme {
                TextGenerationTab(
                    uiState = uiState,
                    onPromptChange = {},
                    onModelChange = {},
                    onGenerate = {}
                )
            }
        }

        composeRule.onAllNodesWithText("使用モデル: Qwen", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("出力テキスト", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("生成中...", useUnmergedTree = true).assertCountEquals(1)
    }
}
