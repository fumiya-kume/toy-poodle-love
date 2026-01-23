package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
 * ルート生成タブ
 *
 * AIでルートを生成
 */
@Composable
fun RouteGenerateTab(
    uiState: ScenarioWriterUiState,
    onStartPointChange: (String) -> Unit,
    onPurposeChange: (String) -> Unit,
    onSpotCountChange: (Int) -> Unit,
    onModelChange: (AIModel) -> Unit,
    onGenerateRoute: () -> Unit,
    onGoToScenario: () -> Unit,
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
            TeslaGroupBox(title = routeGenerateInputTitle()) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    TeslaTextField(
                        label = routeGenerateStartPointLabel(),
                        value = uiState.routeGenerateStartPoint,
                        onValueChange = onStartPointChange,
                        placeholder = routeGenerateStartPointPlaceholder()
                    )

                    TeslaTextField(
                        label = routeGeneratePurposeLabel(),
                        value = uiState.routeGeneratePurpose,
                        onValueChange = onPurposeChange,
                        placeholder = routeGeneratePurposePlaceholder()
                    )

                    TeslaStepper(
                        label = routeGenerateSpotCountLabel(),
                        value = uiState.routeGenerateSpotCount,
                        onValueChange = onSpotCountChange,
                        range = 3..8
                    )

                    ModelPickerView(
                        selectedModel = uiState.routeGenerateModel,
                        onModelSelected = onModelChange
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Button(
                        onClick = onGenerateRoute,
                        enabled = uiState.canGenerateRoute && !uiState.isLoadingRouteGenerate,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = TeslaColors.Accent,
                            disabledContainerColor = TeslaColors.GlassBackground
                        ),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = routeGenerateButtonLabel(uiState.isLoadingRouteGenerate),
                            color = TeslaColors.TextPrimary
                        )
                    }
                }
            }
        }

        // 結果セクション
        item {
            TeslaGroupBox(title = routeGenerateResultTitle()) {
                val result = uiState.routeGenerateResult

                if (result == null) {
                    Text(
                        text = routeGenerateResultEmptyLabel(),
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextSecondary
                    )
                } else {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // 生成モデル
                        result.model?.let { model ->
                            Text(
                                text = routeGenerateModelLabel(model),
                                style = TeslaTheme.typography.labelMedium,
                                color = TeslaColors.TextSecondary
                            )
                        }

                        // スポットリスト
                        result.spots?.let { spots ->
                            Text(
                                text = routeGenerateSpotHeaderLabel(),
                                style = TeslaTheme.typography.titleMedium,
                                color = TeslaColors.TextPrimary
                            )

                            spots.forEachIndexed { index, spot ->
                                Column(
                                    modifier = Modifier.padding(vertical = 4.dp)
                                ) {
                                    Text(
                                        text = routeGenerateSpotLabel(index, spot.name),
                                        style = TeslaTheme.typography.bodyLarge,
                                        color = TeslaColors.TextPrimary
                                    )
                                    Text(
                                        text = routeGenerateSpotTypeLabel(spot.type),
                                        style = TeslaTheme.typography.labelSmall,
                                        color = TeslaColors.Accent
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

                            Spacer(modifier = Modifier.height(8.dp))

                            TextButton(
                                onClick = onGoToScenario,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = routeGenerateGoToScenarioLabel(),
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

internal fun routeGenerateButtonLabel(isLoading: Boolean): String =
    if (isLoading) "生成中..." else "AIでルート生成"

internal fun routeGenerateModelLabel(model: String): String =
    "生成モデル: $model"

internal fun routeGenerateSpotLabel(index: Int, name: String): String =
    "${index + 1}. $name"

internal fun routeGenerateSpotTypeLabel(type: String): String =
    "タイプ: $type"

internal fun routeGenerateResultEmptyLabel(): String = "結果がありません"

internal fun routeGenerateSpotHeaderLabel(): String = "生成されたスポット"

internal fun routeGenerateGoToScenarioLabel(): String = "シナリオ生成へ"

internal fun routeGenerateInputTitle(): String = "入力"

internal fun routeGenerateResultTitle(): String = "結果"

internal fun routeGenerateStartPointLabel(): String = "出発地"

internal fun routeGeneratePurposeLabel(): String = "目的・テーマ"

internal fun routeGenerateSpotCountLabel(): String = "生成地点数"

internal fun routeGenerateStartPointPlaceholder(): String = "例: 東京駅"

internal fun routeGeneratePurposePlaceholder(): String = "例: 皇居周辺の観光スポット"

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun RouteGenerateTabPreview() {
    TeslaTheme {
        RouteGenerateTab(
            uiState = ScenarioWriterUiState(
                routeGenerateStartPoint = "東京駅",
                routeGeneratePurpose = "皇居周辺の観光スポット"
            ),
            onStartPointChange = {},
            onPurposeChange = {},
            onSpotCountChange = {},
            onModelChange = {},
            onGenerateRoute = {},
            onGoToScenario = {}
        )
    }
}
