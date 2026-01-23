package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioModels
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * AIモデル選択ピッカー
 *
 * Gemini / Qwen の切り替えボタン
 */
@Composable
fun ModelPickerView(
    selectedModel: AIModel,
    onModelSelected: (AIModel) -> Unit,
    modifier: Modifier = Modifier,
    label: String = "AIモデル",
    enabled: Boolean = true
) {
    val options = buildModelPickerOptions(selectedModel)
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = label,
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextPrimary
        )

        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(TeslaColors.GlassBackground)
                .border(1.dp, TeslaColors.GlassBorder, RoundedCornerShape(12.dp))
        ) {
            options.forEach { option ->
                Text(
                    text = option.displayName,
                    style = TeslaTheme.typography.labelMedium,
                    color = if (option.isSelected) TeslaColors.TextPrimary else TeslaColors.TextSecondary,
                    modifier = Modifier
                        .clickable(enabled = enabled) { onModelSelected(option.value) }
                        .background(
                            if (option.isSelected) TeslaColors.Accent.copy(alpha = 0.2f)
                            else TeslaColors.Background.copy(alpha = 0f)
                        )
                        .padding(horizontal = 16.dp, vertical = 10.dp)
                )
            }
        }
    }
}

/**
 * シナリオモデル選択ピッカー
 *
 * Gemini / Qwen / Both の切り替えボタン
 */
@Composable
fun ScenarioModelPickerView(
    selectedModels: ScenarioModels,
    onModelsSelected: (ScenarioModels) -> Unit,
    modifier: Modifier = Modifier,
    label: String = "生成モデル",
    enabled: Boolean = true
) {
    val options = buildScenarioModelPickerOptions(selectedModels)
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = label,
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextPrimary
        )

        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(TeslaColors.GlassBackground)
                .border(1.dp, TeslaColors.GlassBorder, RoundedCornerShape(12.dp))
        ) {
            options.forEach { option ->
                Text(
                    text = option.displayName,
                    style = TeslaTheme.typography.labelMedium,
                    color = if (option.isSelected) TeslaColors.TextPrimary else TeslaColors.TextSecondary,
                    modifier = Modifier
                        .clickable(enabled = enabled) { onModelsSelected(option.value) }
                        .background(
                            if (option.isSelected) TeslaColors.Accent.copy(alpha = 0.2f)
                            else TeslaColors.Background.copy(alpha = 0f)
                        )
                        .padding(horizontal = 16.dp, vertical = 10.dp)
                )
            }
        }
    }
}

internal data class PickerOption<T>(
    val value: T,
    val displayName: String,
    val isSelected: Boolean
)

internal fun buildModelPickerOptions(selectedModel: AIModel): List<PickerOption<AIModel>> =
    AIModel.entries.map { model ->
        PickerOption(
            value = model,
            displayName = model.displayName,
            isSelected = model == selectedModel
        )
    }

internal fun buildScenarioModelPickerOptions(
    selectedModels: ScenarioModels
): List<PickerOption<ScenarioModels>> =
    ScenarioModels.entries.map { models ->
        PickerOption(
            value = models,
            displayName = models.displayName,
            isSelected = models == selectedModels
        )
    }

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun ModelPickerViewPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            ModelPickerView(
                selectedModel = AIModel.GEMINI,
                onModelSelected = {}
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun ModelPickerViewQwenSelectedPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            ModelPickerView(
                selectedModel = AIModel.QWEN,
                onModelSelected = {}
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun ScenarioModelPickerViewPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            ScenarioModelPickerView(
                selectedModels = ScenarioModels.BOTH,
                onModelsSelected = {}
            )
        }
    }
}
