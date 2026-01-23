package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class TeslaIconButtonComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun teslaIconButton_invokesClickWhenEnabled() {
        var clicked = false

        composeRule.setContent {
            TeslaTheme {
                TeslaIconButton(
                    icon = Icons.Default.PlayArrow,
                    contentDescription = "Play",
                    onClick = { clicked = true }
                )
            }
        }

        composeRule.onNodeWithContentDescription("Play")
            .assertHasClickAction()
            .performClick()

        assertTrue(clicked)
    }

    @Test
    fun teslaIconButton_isDisabledWhenNotEnabled() {
        composeRule.setContent {
            TeslaTheme {
                TeslaIconButton(
                    icon = Icons.Default.PlayArrow,
                    contentDescription = "Play",
                    onClick = {},
                    enabled = false
                )
            }
        }

        composeRule.onNodeWithContentDescription("Play")
            .assertIsNotEnabled()
    }
}
