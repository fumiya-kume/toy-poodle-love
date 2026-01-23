package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class TeslaAlertCardComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun teslaAlertCard_showsMessage() {
        composeRule.setContent {
            TeslaTheme {
                TeslaAlertCard(
                    message = "通知",
                    variant = TeslaAlertVariant.Info
                )
            }
        }

        composeRule.onNodeWithText("通知").assertIsDisplayed()
    }
}
