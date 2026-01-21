package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.background
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.data.network.RouteOptimizeResponse
import com.fumiyakume.viewer.data.network.RouteWaypoint
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.components.molecules.TeslaTextField
import com.fumiyakume.viewer.ui.components.molecules.TeslaToggle
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.scenariowriter.TravelMode
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * ルート最適化タブ
 *
 * ルート順序を最適化
 */
@Composable
fun RouteOptimizeTab(
    uiState: ScenarioWriterUiState,
    onWaypointInputChange: (String) -> Unit,
    onAddWaypoint: () -> Unit,
    onRemoveWaypoint: (Int) -> Unit,
    onTravelModeChange: (TravelMode) -> Unit,
    onOptimizeOrderChange: (Boolean) -> Unit,
    onOptimizeRoute: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // 設定セクション
        TeslaGroupBox(title = "設定") {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 移動モード選択
                TravelModeSelector(
                    selectedMode = uiState.travelMode,
                    onModeSelected = onTravelModeChange
                )

                // 順序最適化トグル
                TeslaToggle(
                    label = "ウェイポイント順序を最適化",
                    checked = uiState.optimizeWaypointOrder,
                    onCheckedChange = onOptimizeOrderChange
                )
            }
        }

        // ウェイポイント追加セクション
        TeslaGroupBox(title = "ウェイポイント追加") {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    TeslaTextField(
                        label = "住所",
                        value = uiState.waypointInput,
                        onValueChange = onWaypointInputChange,
                        placeholder = "例: 東京駅",
                        modifier = Modifier.weight(1f)
                    )

                    Button(
                        onClick = onAddWaypoint,
                        enabled = uiState.waypointInput.isNotBlank(),
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

        // ウェイポイントリストセクション
        TeslaGroupBox(title = "ウェイポイントリスト (${uiState.routeWaypoints.size}件)") {
            if (uiState.routeWaypoints.isEmpty()) {
                Text(
                    text = "ウェイポイントがありません",
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextSecondary
                )
            } else {
                Column(
                    modifier = Modifier.heightIn(max = 200.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    uiState.routeWaypoints.forEachIndexed { index, waypoint ->
                        WaypointListItem(
                            waypoint = waypoint,
                            index = index,
                            onRemove = { onRemoveWaypoint(index) }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = onOptimizeRoute,
                enabled = uiState.canOptimizeRoute && !uiState.isLoadingRouteOptimize,
                colors = ButtonDefaults.buttonColors(
                    containerColor = TeslaColors.Accent,
                    disabledContainerColor = TeslaColors.GlassBackground
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = if (uiState.isLoadingRouteOptimize) "最適化中..." else "ルート最適化",
                    color = TeslaColors.TextPrimary
                )
            }

            if (uiState.routeWaypoints.size < 2) {
                Text(
                    text = "少なくとも2つのウェイポイントが必要です",
                    style = TeslaTheme.typography.labelSmall,
                    color = TeslaColors.TextTertiary,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }

        // 結果セクション
        TeslaGroupBox(title = "結果") {
            val result = uiState.routeOptimizeResult

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
                    // 最適化されたルート順序
                    result.optimizedOrder?.let { order ->
                        Text(
                            text = "最適化されたルート順序",
                            style = TeslaTheme.typography.titleMedium,
                            color = TeslaColors.TextPrimary
                        )

                        order.forEachIndexed { index, location ->
                            Text(
                                text = "${index + 1}. $location",
                                style = TeslaTheme.typography.bodyMedium,
                                color = TeslaColors.TextSecondary
                            )
                        }
                    }

                    Divider(color = TeslaColors.GlassBorder)

                    // 統計情報
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        result.totalDistanceKm?.let { distance ->
                            Column {
                                Text(
                                    text = "総距離",
                                    style = TeslaTheme.typography.labelSmall,
                                    color = TeslaColors.TextTertiary
                                )
                                Text(
                                    text = "${String.format("%.1f", distance)} km",
                                    style = TeslaTheme.typography.bodyLarge,
                                    color = TeslaColors.TextPrimary
                                )
                            }
                        }

                        result.totalDurationMinutes?.let { duration ->
                            Column {
                                Text(
                                    text = "所要時間",
                                    style = TeslaTheme.typography.labelSmall,
                                    color = TeslaColors.TextTertiary
                                )
                                Text(
                                    text = "$duration 分",
                                    style = TeslaTheme.typography.bodyLarge,
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

@Suppress("UNUSED_PARAMETER")
@Composable
private fun TravelModeSelector(
    selectedMode: TravelMode,
    onModeSelected: (TravelMode) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = "移動モード",
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextPrimary,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(TeslaColors.GlassBackground),
            horizontalArrangement = Arrangement.spacedBy(0.dp)
        ) {
            TravelMode.entries.forEach { mode ->
                val isSelected = mode == selectedMode
                Text(
                    text = mode.displayName,
                    style = TeslaTheme.typography.labelMedium,
                    color = if (isSelected) TeslaColors.TextPrimary else TeslaColors.TextSecondary,
                    modifier = Modifier
                        .background(
                            if (isSelected) TeslaColors.Accent.copy(alpha = 0.2f)
                            else TeslaColors.Background.copy(alpha = 0f)
                        )
                        .padding(horizontal = 16.dp, vertical = 10.dp)
                        .then(
                            Modifier.clip(RoundedCornerShape(12.dp))
                        )
                )
            }
        }
    }
}

@Composable
private fun WaypointListItem(
    waypoint: RouteWaypoint,
    index: Int,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(TeslaColors.GlassBackground)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "${index + 1}. ${waypoint.address}",
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )

        IconButton(onClick = onRemove) {
            Icon(
                imageVector = Icons.Default.Delete,
                contentDescription = "削除",
                tint = TeslaColors.StatusRed
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun RouteOptimizeTabPreview() {
    TeslaTheme {
        RouteOptimizeTab(
            uiState = ScenarioWriterUiState(
                routeWaypoints = listOf(
                    RouteWaypoint("東京駅"),
                    RouteWaypoint("渋谷駅"),
                    RouteWaypoint("新宿駅")
                ),
                travelMode = TravelMode.DRIVE,
                optimizeWaypointOrder = true
            ),
            onWaypointInputChange = {},
            onAddWaypoint = {},
            onRemoveWaypoint = {},
            onTravelModeChange = {},
            onOptimizeOrderChange = {},
            onOptimizeRoute = {}
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun RouteOptimizeTabWithResultPreview() {
    TeslaTheme {
        RouteOptimizeTab(
            uiState = ScenarioWriterUiState(
                routeWaypoints = listOf(
                    RouteWaypoint("東京駅"),
                    RouteWaypoint("渋谷駅"),
                    RouteWaypoint("新宿駅")
                ),
                routeOptimizeResult = RouteOptimizeResponse(
                    success = true,
                    optimizedOrder = listOf("東京駅", "新宿駅", "渋谷駅"),
                    totalDistanceKm = 15.5,
                    totalDurationMinutes = 45
                )
            ),
            onWaypointInputChange = {},
            onAddWaypoint = {},
            onRemoveWaypoint = {},
            onTravelModeChange = {},
            onOptimizeOrderChange = {},
            onOptimizeRoute = {}
        )
    }
}
