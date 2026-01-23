package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import com.fumiyakume.viewer.data.network.GeocodedPlace
import com.fumiyakume.viewer.data.network.LatLng
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class GeocodeTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun geocodeTab_showsEmptyResultState() {
        val uiState = ScenarioWriterUiState(
            geocodeAddresses = "東京駅"
        )

        composeRule.setContent {
            TeslaTheme {
                GeocodeTab(
                    uiState = uiState,
                    onAddressesChange = {},
                    onGeocode = {}
                )
            }
        }

        composeRule.onAllNodesWithText("入力", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果がありません", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("ジオコーディング", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("住所リスト", useUnmergedTree = true).assertCountEquals(1)
    }

    @Test
    fun geocodeTab_showsResultItems() {
        val uiState = ScenarioWriterUiState(
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
        )

        composeRule.setContent {
            TeslaTheme {
                GeocodeTab(
                    uiState = uiState,
                    onAddressesChange = {},
                    onGeocode = {}
                )
            }
        }

        composeRule.onAllNodesWithText("2 件の住所を変換しました", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("東京駅", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("渋谷駅", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("35.681236", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("139.767125", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("35.658034", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("139.701636", useUnmergedTree = true).assertCountEquals(1)
    }
}
