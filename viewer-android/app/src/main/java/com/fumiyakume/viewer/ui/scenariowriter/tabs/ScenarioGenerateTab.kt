package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.data.network.RouteSpot
import com.fumiyakume.viewer.ui.components.molecules.ScenarioModelPickerView
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.components.molecules.TeslaTextField
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioModels
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.scenariowriter.SpotType
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * シナリオ生成タブ
 *
 * スポットのシナリオを生成
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScenarioGenerateTab(
    uiState: ScenarioWriterUiState,
    onRouteNameChange: (String) -> Unit,
    onLanguageChange: (String) -> Unit,
    onModelsChange: (ScenarioModels) -> Unit,
    onAddSpot: (RouteSpot) -> Unit,
    onRemoveSpot: (Int) -> Unit,
    onGenerateScenario: () -> Unit,
    onIntegrate: () -> Unit,
    modifier: Modifier = Modifier
) {
    // スポット追加用の一時状態
    var newSpotName by remember { mutableStateOf("") }
    var newSpotType by remember { mutableStateOf(SpotType.WAYPOINT) }
    var newSpotDescription by remember { mutableStateOf("") }
    var newSpotPoint by remember { mutableStateOf("") }
    var typeExpanded by remember { mutableStateOf(false) }

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
                        label = "ルート名",
                        value = uiState.scenarioRouteName,
                        onValueChange = onRouteNameChange,
                        placeholder = "例: 皇居周辺観光ルート"
                    )

                    TeslaTextField(
                        label = "言語（オプション）",
                        value = uiState.scenarioLanguage,
                        onValueChange = onLanguageChange,
                        placeholder = "例: ja"
                    )

                    ScenarioModelPickerView(
                        selectedModels = uiState.scenarioModels,
                        onModelsSelected = onModelsChange
                    )
                }
            }
        }

        // スポット追加セクション
        item {
            TeslaGroupBox(title = "スポット追加") {
                Column(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    TeslaTextField(
                        label = "スポット名",
                        value = newSpotName,
                        onValueChange = { newSpotName = it },
                        placeholder = "例: 皇居"
                    )

                    // スポットタイプ選択
                    ExposedDropdownMenuBox(
                        expanded = typeExpanded,
                        onExpandedChange = { typeExpanded = it }
                    ) {
                        OutlinedTextField(
                            value = newSpotType.displayName,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("スポットタイプ") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = TeslaColors.Accent,
                                unfocusedBorderColor = TeslaColors.GlassBorder,
                                focusedTextColor = TeslaColors.TextPrimary,
                                unfocusedTextColor = TeslaColors.TextPrimary,
                                focusedLabelColor = TeslaColors.Accent,
                                unfocusedLabelColor = TeslaColors.TextSecondary,
                                focusedContainerColor = TeslaColors.GlassBackground,
                                unfocusedContainerColor = TeslaColors.GlassBackground
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )

                        ExposedDropdownMenu(
                            expanded = typeExpanded,
                            onDismissRequest = { typeExpanded = false }
                        ) {
                            SpotType.entries.forEach { type ->
                                DropdownMenuItem(
                                    text = { Text(type.displayName, color = TeslaColors.TextPrimary) },
                                    onClick = {
                                        newSpotType = type
                                        typeExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    TeslaTextField(
                        label = "説明（オプション）",
                        value = newSpotDescription,
                        onValueChange = { newSpotDescription = it },
                        placeholder = "例: 江戸城の跡地"
                    )

                    TeslaTextField(
                        label = "ポイント（オプション）",
                        value = newSpotPoint,
                        onValueChange = { newSpotPoint = it },
                        placeholder = "例: 歴史的建造物"
                    )

                    Button(
                        onClick = {
                            if (newSpotName.isNotBlank()) {
                                onAddSpot(
                                    RouteSpot(
                                        name = newSpotName,
                                        type = newSpotType.value,
                                        description = newSpotDescription.takeIf { it.isNotBlank() },
                                        point = newSpotPoint.takeIf { it.isNotBlank() }
                                    )
                                )
                                newSpotName = ""
                                newSpotDescription = ""
                                newSpotPoint = ""
                            }
                        },
                        enabled = newSpotName.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = TeslaColors.GlassBackground,
                            disabledContainerColor = TeslaColors.GlassBackground.copy(alpha = 0.5f)
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = null,
                            tint = TeslaColors.TextPrimary
                        )
                        Text(
                            text = "追加",
                            color = TeslaColors.TextPrimary,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        }

        // スポットリストセクション
        item {
            TeslaGroupBox(title = "スポットリスト (${uiState.scenarioSpots.size}件)") {
                if (uiState.scenarioSpots.isEmpty()) {
                    Text(
                        text = "スポットがありません",
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextSecondary
                    )
                } else {
                    Column(
                        modifier = Modifier.heightIn(max = 240.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        uiState.scenarioSpots.forEachIndexed { index, spot ->
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = "${index + 1}. ${spot.name}",
                                        style = TeslaTheme.typography.bodyMedium,
                                        color = TeslaColors.TextPrimary
                                    )
                                    Text(
                                        text = SpotType.entries.firstOrNull { it.value == spot.type }?.displayName ?: spot.type,
                                        style = TeslaTheme.typography.labelSmall,
                                        color = TeslaColors.Accent
                                    )
                                }

                                IconButton(onClick = { onRemoveSpot(index) }) {
                                    Icon(
                                        imageVector = Icons.Default.Delete,
                                        contentDescription = "削除",
                                        tint = TeslaColors.StatusRed
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = onGenerateScenario,
                    enabled = uiState.canGenerateScenario && !uiState.isLoadingScenario,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = TeslaColors.Accent,
                        disabledContainerColor = TeslaColors.GlassBackground
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (uiState.isLoadingScenario) "生成中..." else "シナリオ生成",
                        color = TeslaColors.TextPrimary
                    )
                }
            }
        }

        // 結果セクション
        item {
            TeslaGroupBox(title = "結果") {
                val result = uiState.scenarioResult

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
                        // 統計情報
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            result.routeName?.let {
                                Text(
                                    text = "ルート: $it",
                                    style = TeslaTheme.typography.labelMedium,
                                    color = TeslaColors.TextSecondary
                                )
                            }
                            Text(
                                text = "成功: ${result.successCount ?: 0}/${result.totalCount ?: 0}",
                                style = TeslaTheme.typography.labelMedium,
                                color = TeslaColors.StatusGreen
                            )
                        }

                        Divider(color = TeslaColors.GlassBorder)

                        // シナリオリスト
                        result.spotScenarios?.forEach { spotScenario ->
                            SpotScenarioRow(
                                spotName = spotScenario.spotName,
                                spotType = spotScenario.spotType,
                                scenario = spotScenario.scenario,
                                error = spotScenario.error
                            )
                        }

                        // 統合ボタン
                        if (uiState.canIntegrateScenarios) {
                            TextButton(
                                onClick = onIntegrate,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = "シナリオ統合へ",
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

@Composable
private fun SpotScenarioRow(
    spotName: String,
    spotType: String,
    scenario: String?,
    error: String?
) {
    var expanded by remember { mutableStateOf(false) }

    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = spotName,
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextPrimary
                )
                Text(
                    text = SpotType.entries.firstOrNull { it.value == spotType }?.displayName ?: spotType,
                    style = TeslaTheme.typography.labelSmall,
                    color = TeslaColors.Accent
                )
            }

            if (scenario != null) {
                IconButton(onClick = { expanded = !expanded }) {
                    Icon(
                        imageVector = if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                        contentDescription = if (expanded) "折りたたむ" else "展開する",
                        tint = TeslaColors.TextSecondary
                    )
                }
            }
        }

        AnimatedVisibility(visible = expanded && scenario != null) {
            Text(
                text = scenario ?: "",
                style = TeslaTheme.typography.bodySmall,
                color = TeslaColors.TextSecondary,
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        error?.let {
            Text(
                text = "エラー: $it",
                style = TeslaTheme.typography.labelSmall,
                color = TeslaColors.StatusRed
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun ScenarioGenerateTabPreview() {
    TeslaTheme {
        ScenarioGenerateTab(
            uiState = ScenarioWriterUiState(
                scenarioRouteName = "皇居周辺観光ルート",
                scenarioSpots = listOf(
                    RouteSpot("東京駅", "start", "出発地点"),
                    RouteSpot("皇居", "waypoint", "観光スポット"),
                    RouteSpot("銀座", "destination", "終点")
                )
            ),
            onRouteNameChange = {},
            onLanguageChange = {},
            onModelsChange = {},
            onAddSpot = {},
            onRemoveSpot = {},
            onGenerateScenario = {},
            onIntegrate = {}
        )
    }
}
