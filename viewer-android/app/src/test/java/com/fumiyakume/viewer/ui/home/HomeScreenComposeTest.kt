package com.fumiyakume.viewer.ui.home

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class HomeScreenComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun homeScreen_displaysHeaderAndCards() {
        composeRule.setContent {
            TeslaTheme {
                HomeScreen()
            }
        }

        composeRule.onNodeWithText("Viewer").assertIsDisplayed()
        composeRule.onNodeWithText("ビデオプレイヤー").assertIsDisplayed()
        composeRule.onNodeWithText("シナリオライター").assertIsDisplayed()
    }

    @Test
    fun homeScreen_invokesNavigationCallbacks() {
        var videoClicked = false
        var scenarioClicked = false
        var settingsClicked = false

        composeRule.setContent {
            TeslaTheme {
                HomeScreen(
                    onNavigateToVideoPlayer = { videoClicked = true },
                    onNavigateToScenarioWriter = { scenarioClicked = true },
                    onNavigateToSettings = { settingsClicked = true }
                )
            }
        }

        composeRule.onNodeWithContentDescription("設定").performClick()
        composeRule.onNodeWithText("ビデオプレイヤー").performClick()
        composeRule.onNodeWithText("シナリオライター").performClick()

        assertTrue(settingsClicked)
        assertTrue(videoClicked)
        assertTrue(scenarioClicked)
    }
}
