package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.data.network.GeocodedPlace
import java.util.Locale
import com.fumiyakume.viewer.data.network.LatLng
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.components.molecules.TeslaTextArea
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * ジオコードタブ
 *
 * 住所から座標を取得
 */
@Composable
fun GeocodeTab(
    uiState: ScenarioWriterUiState,
    onAddressesChange: (String) -> Unit,
    onGeocode: () -> Unit,
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
        TeslaGroupBox(title = geocodeInputTitle()) {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                TeslaTextArea(
                    label = geocodeAddressListLabel(),
                    value = uiState.geocodeAddresses,
                    onValueChange = onAddressesChange,
                    placeholder = geocodeAddressesPlaceholder(),
                    minHeight = 120.dp
                )

                Text(
                    text = geocodeInstructionLabel(),
                    style = TeslaTheme.typography.labelSmall,
                    color = TeslaColors.TextTertiary
                )

                Spacer(modifier = Modifier.height(8.dp))

                Button(
                    onClick = onGeocode,
                    enabled = uiState.canGeocode && !uiState.isLoadingGeocode,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = TeslaColors.Accent,
                        disabledContainerColor = TeslaColors.GlassBackground
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = geocodeButtonLabel(uiState.isLoadingGeocode),
                        color = TeslaColors.TextPrimary
                    )
                }
            }
        }

        // 結果セクション
        TeslaGroupBox(title = geocodeResultTitle()) {
            val result = uiState.geocodeResult

            if (result == null) {
                Text(
                    text = geocodeResultEmptyLabel(),
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextSecondary
                )
            } else {
                Column(
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = formatGeocodeResultCount(result.size),
                        style = TeslaTheme.typography.labelMedium,
                        color = TeslaColors.TextSecondary
                    )

                    result.forEach { place ->
                        GeocodeResultItem(place = place)
                        Divider(color = TeslaColors.GlassBorder)
                    }
                }
            }
        }
    }
}

@Composable
private fun GeocodeResultItem(
    place: GeocodedPlace,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // 入力住所
        Text(
            text = place.inputAddress,
            style = TeslaTheme.typography.bodyLarge,
            color = TeslaColors.TextPrimary
        )

        // 座標
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            Column {
                Text(
                    text = geocodeLatitudeLabel(),
                    style = TeslaTheme.typography.labelSmall,
                    color = TeslaColors.TextTertiary
                )
                Text(
                    text = formatCoordinate(place.location.latitude),
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextPrimary
                )
            }

            Column {
                Text(
                    text = geocodeLongitudeLabel(),
                    style = TeslaTheme.typography.labelSmall,
                    color = TeslaColors.TextTertiary
                )
                Text(
                    text = formatCoordinate(place.location.longitude),
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextPrimary
                )
            }
        }

        // フォーマット住所
        Text(
            text = place.formattedAddress,
            style = TeslaTheme.typography.labelMedium,
            color = TeslaColors.TextSecondary
        )
    }
}

internal fun geocodeButtonLabel(isLoading: Boolean): String =
    if (isLoading) "ジオコーディング中..." else "ジオコーディング"

internal fun formatCoordinate(value: Double): String =
    String.format(Locale.US, "%.6f", value)

internal fun formatGeocodeResultCount(count: Int): String =
    "$count 件の住所を変換しました"

internal fun geocodeInstructionLabel(): String =
    "複数の住所を改行で区切って入力してください"

internal fun geocodeResultEmptyLabel(): String = "結果がありません"

internal fun geocodeInputTitle(): String = "入力"

internal fun geocodeResultTitle(): String = "結果"

internal fun geocodeLatitudeLabel(): String = "緯度"

internal fun geocodeLongitudeLabel(): String = "経度"

internal fun geocodeAddressListLabel(): String = "住所リスト"

internal fun geocodeAddressesPlaceholder(): String =
    "1行に1住所を入力\n例:\n東京都千代田区丸の内1丁目\n東京都渋谷区神南1丁目"

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun GeocodeTabPreview() {
    TeslaTheme {
        GeocodeTab(
            uiState = ScenarioWriterUiState(
                geocodeAddresses = "東京都千代田区丸の内1丁目\n東京都渋谷区神南1丁目"
            ),
            onAddressesChange = {},
            onGeocode = {}
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun GeocodeTabWithResultPreview() {
    TeslaTheme {
        GeocodeTab(
            uiState = ScenarioWriterUiState(
                geocodeAddresses = "東京駅\n渋谷駅",
                geocodeResult = listOf(
                    GeocodedPlace(
                        inputAddress = "東京駅",
                        formattedAddress = "日本、〒100-0005 東京都千代田区丸の内1丁目",
                        location = LatLng(35.681236, 139.767125)
                    ),
                    GeocodedPlace(
                        inputAddress = "渋谷駅",
                        formattedAddress = "日本、〒150-0002 東京都渋谷区渋谷2丁目",
                        location = LatLng(35.658034, 139.701636)
                    )
                )
            ),
            onAddressesChange = {},
            onGeocode = {}
        )
    }
}
