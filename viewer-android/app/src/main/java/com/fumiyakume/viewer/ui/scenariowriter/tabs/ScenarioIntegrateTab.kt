package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.components.molecules.TeslaAlertCard
import com.fumiyakume.viewer.ui.components.molecules.TeslaAlertVariant
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * シナリオ統合タブ
 *
 * 複数シナリオを統合
 */
@Composable
fun ScenarioIntegrateTab(
    uiState: ScenarioWriterUiState,
    onIntegrate: () -> Unit,
    onGoToScenarioGenerate: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        val scenarioResult = uiState.scenarioResult
        val integrationResult = uiState.scenarioIntegrationResult

        when (resolveScenarioIntegrateState(scenarioResult, integrationResult)) {
            ScenarioIntegrateState.NoScenarioResult -> {
                TeslaAlertCard(
                    message = scenarioIntegrateNoScenarioMessage(),
                    variant = TeslaAlertVariant.Info,
                    modifier = Modifier.fillMaxWidth()
                )

                TextButton(
                    onClick = onGoToScenarioGenerate,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                ) {
                    Text(
                        text = scenarioIntegrateGoToScenarioLabel(),
                        color = TeslaColors.Accent
                    )
                }
            }

            ScenarioIntegrateState.ReadyToIntegrate -> {
                val nonNullScenarioResult = requireNotNull(scenarioResult)
                TeslaGroupBox(title = scenarioIntegrateTitleLabel()) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = scenarioIntegrateIntroLabel(),
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.TextPrimary
                        )

                        nonNullScenarioResult.spotScenarios
                            ?.filter { it.scenario != null }
                            ?.forEach { spotScenario ->
                            Text(
                                text = scenarioIntegrateSpotLabel(spotScenario.spotName),
                                style = TeslaTheme.typography.bodyMedium,
                                color = TeslaColors.TextSecondary
                            )
                        }

                        Button(
                            onClick = onIntegrate,
                            enabled = uiState.canIntegrateScenarios && !uiState.isLoadingScenarioIntegrate,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = TeslaColors.Accent,
                                disabledContainerColor = TeslaColors.GlassBackground
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = scenarioIntegrateButtonLabel(uiState.isLoadingScenarioIntegrate),
                                color = TeslaColors.TextPrimary
                            )
                        }
                    }
                }
            }

            ScenarioIntegrateState.HasIntegrationResult -> {
                val nonNullIntegrationResult = requireNotNull(integrationResult)
                TeslaGroupBox(title = scenarioIntegrateResultTitleLabel()) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // ヘッダー
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.AutoAwesome,
                                contentDescription = null,
                                tint = TeslaColors.StatusOrange
                            )
                            Text(
                                text = scenarioIntegrateAiHeaderLabel(),
                                style = TeslaTheme.typography.titleMedium,
                                color = TeslaColors.TextPrimary
                            )
                        }

                        // メタデータ
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            nonNullIntegrationResult.routeName?.let {
                                Text(
                                    text = scenarioIntegrateRouteLabel(it),
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            nonNullIntegrationResult.usedModel?.let {
                                Text(
                                    text = scenarioIntegrateModelLabel(it),
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            nonNullIntegrationResult.integratedAt?.let {
                                Text(
                                    text = scenarioIntegrateIntegratedAtLabel(it),
                                    style = TeslaTheme.typography.labelSmall,
                                    color = TeslaColors.TextTertiary
                                )
                            }
                            nonNullIntegrationResult.processingTimeMs?.let {
                                Text(
                                    text = scenarioIntegrateProcessingTimeLabel(it),
                                    style = TeslaTheme.typography.labelSmall,
                                    color = TeslaColors.TextTertiary
                                )
                            }
                        }

                        Divider(color = TeslaColors.GlassBorder)

                        // 統合スクリプト
                        nonNullIntegrationResult.integratedScript?.let { script ->
                            SelectionContainer {
                                Text(
                                    text = script,
                                    style = TeslaTheme.typography.bodyMedium,
                                    color = TeslaColors.TextPrimary
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

internal fun scenarioIntegrateButtonLabel(isLoading: Boolean): String =
    if (isLoading) "統合中..." else "シナリオを統合"

internal fun scenarioIntegrateProcessingTimeLabel(timeMs: Long): String =
    "処理時間: ${timeMs}ms"

internal fun scenarioIntegrateNoScenarioMessage(): String =
    "統合するシナリオがありません。まずシナリオ生成タブでシナリオを生成してください。"

internal fun scenarioIntegrateGoToScenarioLabel(): String = "シナリオ生成タブへ"

internal fun scenarioIntegrateTitleLabel(): String = "シナリオ統合"

internal fun scenarioIntegrateIntroLabel(): String = "以下のシナリオを統合します"

internal fun scenarioIntegrateResultTitleLabel(): String = "統合結果"

internal fun scenarioIntegrateAiHeaderLabel(): String = "AIによる統合シナリオ"

internal fun scenarioIntegrateRouteLabel(routeName: String): String = "ルート: $routeName"

internal fun scenarioIntegrateModelLabel(model: String): String = "モデル: $model"

internal fun scenarioIntegrateIntegratedAtLabel(integratedAt: String): String =
    "統合日時: $integratedAt"

internal fun scenarioIntegrateSpotLabel(spotName: String): String = "• $spotName"

internal enum class ScenarioIntegrateState {
    NoScenarioResult,
    ReadyToIntegrate,
    HasIntegrationResult
}

internal fun resolveScenarioIntegrateState(
    scenarioResult: com.fumiyakume.viewer.data.network.ScenarioOutput?,
    integrationResult: com.fumiyakume.viewer.data.network.ScenarioIntegrationOutput?
): ScenarioIntegrateState = when {
    scenarioResult == null -> ScenarioIntegrateState.NoScenarioResult
    integrationResult == null -> ScenarioIntegrateState.ReadyToIntegrate
    else -> ScenarioIntegrateState.HasIntegrationResult
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun ScenarioIntegrateTabEmptyPreview() {
    TeslaTheme {
        ScenarioIntegrateTab(
            uiState = ScenarioWriterUiState(),
            onIntegrate = {},
            onGoToScenarioGenerate = {}
        )
    }
}
