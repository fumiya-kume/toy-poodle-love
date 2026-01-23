package com.fumiyakume.viewer.ui.scenariowriter.tabs

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import com.fumiyakume.viewer.data.network.RouteOptimizeResponse
import com.fumiyakume.viewer.data.network.RouteWaypoint
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterUiState
import com.fumiyakume.viewer.ui.scenariowriter.TravelMode
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RouteOptimizeTabComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun routeOptimizeTab_showsEmptyState() {
        val uiState = ScenarioWriterUiState(
            waypointInput = "",
            travelMode = TravelMode.DRIVE,
            optimizeWaypointOrder = true
        )

        composeRule.setContent {
            TeslaTheme {
                RouteOptimizeTab(
                    uiState = uiState,
                    onWaypointInputChange = {},
                    onAddWaypoint = {},
                    onRemoveWaypoint = {},
                    onTravelModeChange = {},
                    onOptimizeOrderChange = {},
                    onOptimizeRoute = {}
                )
            }
        }

        composeRule.onAllNodesWithText("設定", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("ウェイポイント追加", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("ウェイポイントリスト (0件)", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("ウェイポイントがありません", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("少なくとも2つのウェイポイントが必要です", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("ルート最適化", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("結果がありません", useUnmergedTree = true).assertCountEquals(1)
    }

    @Test
    fun routeOptimizeTab_showsResultDetails() {
        val result = RouteOptimizeResponse(
            success = true,
            optimizedOrder = listOf("東京駅", "渋谷駅"),
            totalDistanceKm = 15.5,
            totalDurationMinutes = 45
        )
        val uiState = ScenarioWriterUiState(
            routeWaypoints = listOf(
                RouteWaypoint("東京駅"),
                RouteWaypoint("渋谷駅")
            ),
            routeOptimizeResult = result
        )

        composeRule.setContent {
            TeslaTheme {
                RouteOptimizeTab(
                    uiState = uiState,
                    onWaypointInputChange = {},
                    onAddWaypoint = {},
                    onRemoveWaypoint = {},
                    onTravelModeChange = {},
                    onOptimizeOrderChange = {},
                    onOptimizeRoute = {}
                )
            }
        }

        composeRule.onAllNodesWithText("最適化されたルート順序", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("1. 東京駅", useUnmergedTree = true).assertCountEquals(2)
        composeRule.onAllNodesWithText("2. 渋谷駅", useUnmergedTree = true).assertCountEquals(2)
        composeRule.onAllNodesWithText("総距離", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("15.5 km", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("所要時間", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("45 分", useUnmergedTree = true).assertCountEquals(1)
    }
}
