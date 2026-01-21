package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.components.molecules.ModelPickerView
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.components.molecules.TeslaTextArea
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * テキスト生成タブ
 *
 * AIでテキストを生成
 */
@Composable
fun TextGenerationTab(
    uiState: ScenarioWriterUiState,
    onPromptChange: (String) -> Unit,
    onModelChange: (AIModel) -> Unit,
    onGenerate: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // 入力セクション
        TeslaGroupBox(title = "入力") {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                ModelPickerView(
                    selectedModel = uiState.textGenerationModel,
                    onModelSelected = onModelChange
                )

                TeslaTextArea(
                    label = "プロンプト",
                    value = uiState.textGenerationPrompt,
                    onValueChange = onPromptChange,
                    placeholder = "AIに質問したい内容を入力してください",
                    minHeight = 120.dp
                )

                Spacer(modifier = Modifier.height(8.dp))

                Button(
                    onClick = onGenerate,
                    enabled = uiState.canGenerateText && !uiState.isLoadingTextGeneration,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = TeslaColors.Accent,
                        disabledContainerColor = TeslaColors.GlassBackground
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (uiState.isLoadingTextGeneration) "生成中..." else "生成",
                        color = TeslaColors.TextPrimary
                    )
                }
            }
        }

        // 結果セクション
        TeslaGroupBox(title = "結果") {
            val result = uiState.textGenerationResult

            if (result == null) {
                Text(
                    text = "結果がありません",
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextSecondary
                )
            } else {
                Column(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    uiState.textGenerationResultModel?.let { model ->
                        Text(
                            text = "使用モデル: ${model.displayName}",
                            style = TeslaTheme.typography.labelMedium,
                            color = TeslaColors.TextSecondary
                        )
                    }

                    SelectionContainer {
                        Text(
                            text = result,
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.TextPrimary
                        )
                    }
                }
            }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun TextGenerationTabPreview() {
    TeslaTheme {
        TextGenerationTab(
            uiState = ScenarioWriterUiState(
                textGenerationPrompt = "東京の観光スポットについて教えてください",
                textGenerationModel = AIModel.GEMINI
            ),
            onPromptChange = {},
            onModelChange = {},
            onGenerate = {}
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun TextGenerationTabWithResultPreview() {
    TeslaTheme {
        TextGenerationTab(
            uiState = ScenarioWriterUiState(
                textGenerationPrompt = "東京の観光スポットについて教えてください",
                textGenerationModel = AIModel.GEMINI,
                textGenerationResult = "東京には多くの観光スポットがあります。\n\n1. 浅草寺 - 東京最古の寺院\n2. 東京スカイツリー - 634mの電波塔\n3. 皇居 - 天皇陛下のお住まい\n\nこれらのスポットは観光客に人気です。",
                textGenerationResultModel = AIModel.GEMINI
            ),
            onPromptChange = {},
            onModelChange = {},
            onGenerate = {}
        )
    }
}
