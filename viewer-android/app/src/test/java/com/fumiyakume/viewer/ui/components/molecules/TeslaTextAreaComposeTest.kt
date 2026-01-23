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
class TeslaTextAreaComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun teslaTextArea_showsLabel() {
        composeRule.setContent {
            TeslaTheme {
                TeslaTextArea(
                    label = "詳細",
                    value = "",
                    onValueChange = {},
                    placeholder = "入力してください"
                )
            }
        }

        composeRule.onNodeWithText("詳細").assertIsDisplayed()
    }
}
