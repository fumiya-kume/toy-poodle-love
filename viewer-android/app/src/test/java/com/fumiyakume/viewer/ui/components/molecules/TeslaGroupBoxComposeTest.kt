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
class TeslaGroupBoxComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun teslaGroupBox_rendersTitleAndContent() {
        composeRule.setContent {
            TeslaTheme {
                TeslaGroupBox(title = "Section") {
                    androidx.compose.material3.Text("Content")
                }
            }
        }

        composeRule.onNodeWithText("Section").assertIsDisplayed()
        composeRule.onNodeWithText("Content").assertIsDisplayed()
    }
}
