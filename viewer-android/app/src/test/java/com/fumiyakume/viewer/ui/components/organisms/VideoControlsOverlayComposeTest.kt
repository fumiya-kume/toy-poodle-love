package com.fumiyakume.viewer.ui.components.organisms

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class VideoControlsOverlayComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun videoControlsOverlay_showsBackAndPlayControls() {
        composeRule.setContent {
            TeslaTheme {
                VideoControlsOverlay(
                    isVisible = true,
                    isPlaying = false,
                    currentPositionMs = 0L,
                    durationMs = 10_000L,
                    overlayOpacity = 0.5f,
                    onNavigateBack = {},
                    onPlayPauseClick = {},
                    onSeek = {},
                    onOpacityChange = {},
                    modifier = androidx.compose.ui.Modifier
                )
            }
        }

        composeRule.onNodeWithContentDescription("戻る").assertIsDisplayed()
        composeRule.onNodeWithContentDescription("再生").assertIsDisplayed()
    }
}
