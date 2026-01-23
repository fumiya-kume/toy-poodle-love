package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.components.molecules.ModelPickerView
import java.util.Locale
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.components.molecules.TeslaStepper
import com.fumiyakume.viewer.ui.components.molecules.TeslaTextField
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Pipelineタブ
 *
 * E2Eパイプライン実行（最優先機能）
 * 出発地とテーマからルート生成→最適化→シナリオ生成まで一括実行
 */
@Composable
fun PipelineTab(
    uiState: ScenarioWriterUiState,
    onStartPointChange: (String) -> Unit,
    onPurposeChange: (String) -> Unit,
    onSpotCountChange: (Int) -> Unit,
    onModelChange: (AIModel) -> Unit,
    onRunPipeline: () -> Unit,
    onShowOnMap: () -> Unit,
    onGenerateScenario: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp)
            .testTag("pipeline_list"),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // 入力セクション
        item {
            TeslaGroupBox(title = pipelineInputTitle()) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    TeslaTextField(
                        label = pipelineStartPointLabel(),
                        value = uiState.pipelineStartPoint,
                        onValueChange = onStartPointChange,
                        placeholder = pipelineStartPointPlaceholder()
                    )

                    TeslaTextField(
                        label = pipelinePurposeLabel(),
                        value = uiState.pipelinePurpose,
                        onValueChange = onPurposeChange,
                        placeholder = pipelinePurposePlaceholder()
                    )

                    TeslaStepper(
                        label = pipelineSpotCountLabel(),
                        value = uiState.pipelineSpotCount,
                        onValueChange = onSpotCountChange,
                        range = 3..8
                    )

                    ModelPickerView(
                        selectedModel = uiState.pipelineModel,
                        onModelSelected = onModelChange
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Button(
                        onClick = onRunPipeline,
                        enabled = uiState.canRunPipeline && !uiState.isLoadingPipeline,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = TeslaColors.Accent,
                            disabledContainerColor = TeslaColors.GlassBackground
                        ),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = pipelineButtonLabel(uiState.isLoadingPipeline),
                            color = TeslaColors.TextPrimary
                        )
                    }
                }
            }
        }

        // 結果セクション
        item {
            TeslaGroupBox(title = pipelineResultTitle()) {
                val result = uiState.pipelineResult

                if (result == null) {
                    Text(
                        text = pipelineResultEmptyLabel(),
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextSecondary
                    )
                } else {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // ルート名
                        result.routeName?.let { routeName ->
                            Text(
                                text = pipelineRouteNameLabel(routeName),
                                style = TeslaTheme.typography.headlineMedium,
                                color = TeslaColors.TextPrimary
                            )
                        }

                        // スポットリスト
                        result.spots?.let { spots ->
                            Text(
                                text = pipelineSpotHeaderLabel(),
                                style = TeslaTheme.typography.titleMedium,
                                color = TeslaColors.TextPrimary
                            )

                            spots.forEachIndexed { index, spot ->
                                Column {
                                    Text(
                                        text = pipelineSpotLabel(index, spot.name),
                                        style = TeslaTheme.typography.bodyLarge,
                                        color = TeslaColors.TextPrimary
                                    )
                                    Text(
                                        text = pipelineSpotDescriptionLabel(spot.description),
                                        style = TeslaTheme.typography.bodyMedium,
                                        color = TeslaColors.TextSecondary
                                    )
                                    spot.note?.let { note ->
                                        Text(
                                            text = pipelineSpotNoteLabel(note),
                                            style = TeslaTheme.typography.labelSmall,
                                            color = TeslaColors.TextTertiary
                                        )
                                    }
                                }
                            }
                        }

                        HorizontalDivider(color = TeslaColors.GlassBorder)

                        // 統計情報
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            result.totalDistanceKm?.let { distance ->
                                Text(
                                    text = pipelineDistanceLabel(distance),
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            result.totalDurationMinutes?.let { duration ->
                                Text(
                                    text = pipelineDurationLabel(duration),
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            result.processingTimeMs?.let { time ->
                                Text(
                                    text = pipelineProcessingTimeLabel(time),
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextTertiary
                                )
                            }
                        }

                        // アクションボタン
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            TextButton(
                                onClick = onShowOnMap,
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = pipelineShowOnMapLabel(),
                                    color = TeslaColors.Accent
                                )
                            }

                            TextButton(
                                onClick = onGenerateScenario,
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = pipelineGenerateScenarioLabel(),
                                    color = TeslaColors.Accent
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

internal fun pipelineButtonLabel(isLoading: Boolean): String =
    if (isLoading) "実行中..." else "パイプライン実行"

internal fun formatPipelineDistanceKm(distanceKm: Double): String =
    String.format(Locale.US, "%.1f km", distanceKm)

internal fun formatPipelineDurationMinutes(minutes: Int): String =
    "$minutes 分"

internal fun formatPipelineProcessingTimeMs(timeMs: Long): String =
    "$timeMs ms"

internal fun pipelineResultEmptyLabel(): String = "結果がありません"

internal fun pipelineRouteNameLabel(routeName: String): String = routeName

internal fun pipelineSpotHeaderLabel(): String = "生成されたスポット"

internal fun pipelineSpotLabel(index: Int, name: String): String =
    "${index + 1}. $name"

internal fun pipelineSpotDescriptionLabel(description: String): String = description

internal fun pipelineSpotNoteLabel(note: String): String = note

internal fun pipelineDistanceLabel(distanceKm: Double): String =
    "総距離: ${formatPipelineDistanceKm(distanceKm)}"

internal fun pipelineDurationLabel(minutes: Int): String =
    "所要時間: ${formatPipelineDurationMinutes(minutes)}"

internal fun pipelineProcessingTimeLabel(timeMs: Long): String =
    "処理時間: ${formatPipelineProcessingTimeMs(timeMs)}"

internal fun pipelineShowOnMapLabel(): String = "マップで表示"

internal fun pipelineGenerateScenarioLabel(): String = "シナリオを生成"

internal fun pipelineInputTitle(): String = "入力"

internal fun pipelineResultTitle(): String = "結果"

internal fun pipelineStartPointLabel(): String = "出発地"

internal fun pipelinePurposeLabel(): String = "目的・テーマ"

internal fun pipelineSpotCountLabel(): String = "生成地点数"

internal fun pipelineStartPointPlaceholder(): String = "例: 東京駅"

internal fun pipelinePurposePlaceholder(): String = "例: 皇居周辺の観光スポット"

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun PipelineTabPreview() {
    TeslaTheme {
        PipelineTab(
            uiState = ScenarioWriterUiState(
                pipelineStartPoint = "東京駅",
                pipelinePurpose = "皇居周辺の観光スポット",
                pipelineSpotCount = 5,
                pipelineModel = AIModel.GEMINI
            ),
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
