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
import androidx.compose.material3.Divider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.components.molecules.ModelPickerView
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
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // 入力セクション
        item {
            TeslaGroupBox(title = "入力") {
                Column(
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    TeslaTextField(
                        label = "出発地",
                        value = uiState.pipelineStartPoint,
                        onValueChange = onStartPointChange,
                        placeholder = "例: 東京駅"
                    )

                    TeslaTextField(
                        label = "目的・テーマ",
                        value = uiState.pipelinePurpose,
                        onValueChange = onPurposeChange,
                        placeholder = "例: 皇居周辺の観光スポット"
                    )

                    TeslaStepper(
                        label = "生成地点数",
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
                            text = if (uiState.isLoadingPipeline) "実行中..." else "パイプライン実行",
                            color = TeslaColors.TextPrimary
                        )
                    }
                }
            }
        }

        // 結果セクション
        item {
            TeslaGroupBox(title = "結果") {
                val result = uiState.pipelineResult

                if (result == null) {
                    Text(
                        text = "結果がありません",
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
                                text = routeName,
                                style = TeslaTheme.typography.headlineMedium,
                                color = TeslaColors.TextPrimary
                            )
                        }

                        // スポットリスト
                        result.spots?.let { spots ->
                            Text(
                                text = "生成されたスポット",
                                style = TeslaTheme.typography.titleMedium,
                                color = TeslaColors.TextPrimary
                            )

                            spots.forEachIndexed { index, spot ->
                                Column {
                                    Text(
                                        text = "${index + 1}. ${spot.name}",
                                        style = TeslaTheme.typography.bodyLarge,
                                        color = TeslaColors.TextPrimary
                                    )
                                    Text(
                                        text = spot.description,
                                        style = TeslaTheme.typography.bodyMedium,
                                        color = TeslaColors.TextSecondary
                                    )
                                    spot.note?.let { note ->
                                        Text(
                                            text = note,
                                            style = TeslaTheme.typography.labelSmall,
                                            color = TeslaColors.TextTertiary
                                        )
                                    }
                                }
                            }
                        }

                        Divider(color = TeslaColors.GlassBorder)

                        // 統計情報
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            result.totalDistanceKm?.let { distance ->
                                Text(
                                    text = "総距離: ${String.format("%.1f", distance)} km",
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            result.totalDurationMinutes?.let { duration ->
                                Text(
                                    text = "所要時間: ${duration} 分",
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            result.processingTimeMs?.let { time ->
                                Text(
                                    text = "処理時間: ${time} ms",
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
                                    text = "マップで表示",
                                    color = TeslaColors.Accent
                                )
                            }

                            TextButton(
                                onClick = onGenerateScenario,
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = "シナリオを生成",
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
