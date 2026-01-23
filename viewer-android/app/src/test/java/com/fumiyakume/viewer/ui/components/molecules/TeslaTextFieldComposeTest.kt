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
class TeslaTextFieldComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun teslaTextField_showsLabelAndError() {
        composeRule.setContent {
            TeslaTheme {
                TeslaTextField(
                    label = "名前",
                    value = "",
                    onValueChange = {},
                    isError = true,
                    errorMessage = "必須です"
                )
            }
        }

        composeRule.onNodeWithText("名前").assertIsDisplayed()
        composeRule.onNodeWithText("必須です").assertIsDisplayed()
    }
}
