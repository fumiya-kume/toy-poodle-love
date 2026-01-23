package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Map
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.data.network.LatLng
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.scenariowriter.MapSpot
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapType
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import com.google.android.gms.maps.model.LatLng as GmsLatLng

/**
 * シナリオマップタブ
 *
 * Google Maps Composeを使用してスポットをマップに表示
 * マーカーの色はスポットタイプ（start=緑, waypoint=青, destination=赤）で分類
 */
@Composable
fun ScenarioMapTab(
    uiState: ScenarioWriterUiState,
    onSpotSelected: (String?) -> Unit,
    onGoToPipeline: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        if (uiState.mapSpots.isEmpty()) {
            // 空状態
            EmptyMapState(
                onGoToPipeline = onGoToPipeline,
                modifier = Modifier.align(Alignment.Center)
            )
        } else {
            // マップ表示（Google Maps Compose）
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Google Maps エリア
                val cameraPositionState = rememberCameraPositionState()

                // スポットがある場合、最初のスポットにカメラを移動
                LaunchedEffect(uiState.mapSpots) {
                    if (uiState.mapSpots.isNotEmpty()) {
                        val firstSpot = uiState.mapSpots.first()
                        cameraPositionState.animate(
                            CameraUpdateFactory.newLatLngZoom(
                                GmsLatLng(firstSpot.coordinate.latitude, firstSpot.coordinate.longitude),
                                13f
                            )
                        )
                    }
                }

                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                ) {
                    GoogleMap(
                        modifier = Modifier.fillMaxSize(),
                        cameraPositionState = cameraPositionState,
                        properties = MapProperties(
                            mapType = MapType.NORMAL,
                            isMyLocationEnabled = false
                        ),
                        uiSettings = MapUiSettings(
                            zoomControlsEnabled = true,
                            mapToolbarEnabled = false
                        )
                    ) {
                        uiState.mapSpots.forEach { spot ->
                            val isSelected = spot.id == uiState.selectedMapSpotId
                            val markerColor = markerHue(spot.type, isSelected)

                            Marker(
                                state = MarkerState(
                                    position = GmsLatLng(
                                        spot.coordinate.latitude,
                                        spot.coordinate.longitude
                                    )
                                ),
                                title = spot.name,
                                snippet = spot.description,
                                icon = BitmapDescriptorFactory.defaultMarker(markerColor),
                                onClick = {
                                    onSpotSelected(spot.id)
                                    true
                                }
                            )
                        }
                    }
                }

                // スポットリスト
                TeslaGroupBox(title = mapSpotListTitleLabel()) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        uiState.mapSpots.forEachIndexed { index, spot ->
                            SpotListItem(
                                spot = spot,
                                index = index,
                                isSelected = spot.id == uiState.selectedMapSpotId,
                                onClick = { onSpotSelected(spot.id) }
                            )
                        }
                    }
                }

                // 選択されたスポットの詳細
                uiState.selectedMapSpotId?.let { selectedId ->
                    uiState.mapSpots.find { it.id == selectedId }?.let { selectedSpot ->
                        SpotInfoPanel(spot = selectedSpot)
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyMapState(
    onGoToPipeline: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Map,
            contentDescription = null,
            tint = TeslaColors.TextSecondary
        )

        Text(
            text = mapEmptyTitleLabel(),
            style = TeslaTheme.typography.titleMedium,
            color = TeslaColors.TextSecondary
        )

        Text(
            text = mapEmptySubtitleLabel(),
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextTertiary
        )

        TextButton(onClick = onGoToPipeline) {
            Text(
                text = mapEmptyActionLabel(),
                color = TeslaColors.Accent
            )
        }
    }
}

@Composable
private fun SpotListItem(
    spot: MapSpot,
    index: Int,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val markerColor = mapSpotListMarkerColor(spot.type)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .clickable { onClick() }
            .background(mapSpotListBackgroundColor(isSelected))
            .padding(12.dp)
    ) {
        Column {
            Text(
                text = mapSpotLabel(index, spot.name),
                style = TeslaTheme.typography.bodyMedium,
                color = if (isSelected) TeslaColors.Accent else TeslaColors.TextPrimary
            )
            Text(
                text = mapSpotTypeLabel(spot.type),
                style = TeslaTheme.typography.labelSmall,
                color = markerColor
            )
        }
    }
}

@Composable
private fun SpotInfoPanel(
    spot: MapSpot,
    modifier: Modifier = Modifier
) {
    TeslaGroupBox(
        title = mapSpotInfoTitleLabel(spot.name),
        modifier = modifier
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = mapSpotInfoTypeLabel(spot.type),
                style = TeslaTheme.typography.labelMedium,
                color = TeslaColors.TextSecondary
            )

            spot.address?.let { address ->
                Text(
                    text = mapSpotAddressLabel(address),
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextSecondary
                )
            }

            spot.description?.let { description ->
                Text(
                    text = mapSpotDescriptionLabel(description),
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextPrimary
                )
            }

            Text(
                text = mapSpotCoordinateLabel(spot.coordinate.latitude, spot.coordinate.longitude),
                style = TeslaTheme.typography.labelSmall,
                color = TeslaColors.TextTertiary
            )
        }
    }
}

/**
 * スポットタイプと選択状態に基づいてマーカーの色を返す
 *
 * @param type スポットタイプ (start, waypoint, destination)
 * @param isSelected 選択されているかどうか
 * @return BitmapDescriptorFactory用のHue値
 */
internal fun markerHue(type: String, isSelected: Boolean): Float = when {
    isSelected -> BitmapDescriptorFactory.HUE_ORANGE
    type == "start" -> BitmapDescriptorFactory.HUE_GREEN
    type == "destination" -> BitmapDescriptorFactory.HUE_RED
    else -> BitmapDescriptorFactory.HUE_AZURE // waypoint
}

internal fun mapSpotLabel(index: Int, name: String): String =
    "${index + 1}. $name"

internal fun mapSpotTypeLabel(type: String): String = type

internal fun mapSpotInfoTypeLabel(type: String): String =
    "タイプ: $type"

internal fun mapSpotCoordinateLabel(latitude: Double, longitude: Double): String =
    "座標: $latitude, $longitude"

internal fun mapSpotListTitleLabel(): String = "スポット一覧"

internal fun mapEmptyTitleLabel(): String = "マップに表示するデータがありません"

internal fun mapEmptySubtitleLabel(): String =
    "Pipelineを実行して「マップで表示」をクリックしてください"

internal fun mapEmptyActionLabel(): String = "Pipelineタブへ"

internal fun mapSpotAddressLabel(address: String): String = "住所: $address"

internal fun mapSpotDescriptionLabel(description: String): String = description

internal fun mapSpotInfoTitleLabel(name: String): String = name

internal fun mapSpotListMarkerColor(type: String) = when (type) {
    "start" -> TeslaColors.StatusGreen
    "waypoint" -> TeslaColors.Accent
    "destination" -> TeslaColors.StatusRed
    else -> TeslaColors.TextSecondary
}

internal fun mapSpotListBackgroundColor(isSelected: Boolean) =
    if (isSelected) TeslaColors.Accent.copy(alpha = 0.1f)
    else TeslaColors.GlassBackground

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun ScenarioMapTabEmptyPreview() {
    TeslaTheme {
        ScenarioMapTab(
            uiState = ScenarioWriterUiState(),
            onSpotSelected = {},
            onGoToPipeline = {}
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun ScenarioMapTabWithSpotsPreview() {
    TeslaTheme {
        ScenarioMapTab(
            uiState = ScenarioWriterUiState(
                mapSpots = listOf(
                    MapSpot("1", "東京駅", "start", "出発地点", "東京都千代田区", LatLng(35.681236, 139.767125)),
                    MapSpot("2", "皇居", "waypoint", "観光スポット", null, LatLng(35.685175, 139.752800)),
                    MapSpot("3", "銀座", "destination", "終点", null, LatLng(35.671987, 139.765021))
                ),
                selectedMapSpotId = "2"
            ),
            onSpotSelected = {},
            onGoToPipeline = {}
        )
    }
}
