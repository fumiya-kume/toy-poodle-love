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

        when {
            // シナリオ結果がない場合
            scenarioResult == null -> {
                TeslaAlertCard(
                    message = "統合するシナリオがありません。まずシナリオ生成タブでシナリオを生成してください。",
                    variant = TeslaAlertVariant.Info,
                    modifier = Modifier.fillMaxWidth()
                )

                TextButton(
                    onClick = onGoToScenarioGenerate,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                ) {
                    Text(
                        text = "シナリオ生成タブへ",
                        color = TeslaColors.Accent
                    )
                }
            }

            // シナリオはあるが統合結果がない場合
            integrationResult == null -> {
                TeslaGroupBox(title = "シナリオ統合") {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = "以下のシナリオを統合します",
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.TextPrimary
                        )

                        scenarioResult.spotScenarios?.filter { it.scenario != null }?.forEach { spotScenario ->
                            Text(
                                text = "• ${spotScenario.spotName}",
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
                                text = if (uiState.isLoadingScenarioIntegrate) "統合中..." else "シナリオを統合",
                                color = TeslaColors.TextPrimary
                            )
                        }
                    }
                }
            }

            // 統合結果がある場合
            else -> {
                TeslaGroupBox(title = "統合結果") {
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
                                text = "AIによる統合シナリオ",
                                style = TeslaTheme.typography.titleMedium,
                                color = TeslaColors.TextPrimary
                            )
                        }

                        // メタデータ
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            integrationResult.routeName?.let {
                                Text(
                                    text = "ルート: $it",
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            integrationResult.usedModel?.let {
                                Text(
                                    text = "モデル: $it",
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            integrationResult.integratedAt?.let {
                                Text(
                                    text = "統合日時: $it",
                                    style = TeslaTheme.typography.labelSmall,
                                    color = TeslaColors.TextTertiary
                                )
                            }
                            integrationResult.processingTimeMs?.let {
                                Text(
                                    text = "処理時間: ${it}ms",
                                    style = TeslaTheme.typography.labelSmall,
                                    color = TeslaColors.TextTertiary
                                )
                            }
                        }

                        Divider(color = TeslaColors.GlassBorder)

                        // 統合スクリプト
                        integrationResult.integratedScript?.let { script ->
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
