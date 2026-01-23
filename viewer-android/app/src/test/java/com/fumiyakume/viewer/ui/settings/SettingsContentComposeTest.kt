package com.fumiyakume.viewer.ui.settings

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import com.fumiyakume.viewer.BuildConfig
import com.fumiyakume.viewer.data.local.AppSettings
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SettingsContentComposeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun settingsContent_displaysSectionsAndValues() {
        val settings = AppSettings(
            controlHideDelayMs = 3000L,
            defaultOverlayOpacity = 0.5f,
            defaultAIModel = "gemini"
        )

        composeRule.setContent {
            TeslaTheme {
                SettingsContent(
                    settings = settings,
                    onControlHideDelayChange = {},
                    onOverlayOpacityChange = {},
                    onAIModelChange = {}
                )
            }
        }

        composeRule.onAllNodesWithText("ビデオプレイヤー", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("シナリオライター", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("アプリ情報", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("コントロール非表示時間", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("デフォルトオーバーレイ透明度", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("デフォルトAIモデル", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("3 秒", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText("50%", useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText(BuildConfig.VERSION_NAME, useUnmergedTree = true).assertCountEquals(1)
        composeRule.onAllNodesWithText(if (BuildConfig.DEBUG) "Debug" else "Release", useUnmergedTree = true).assertCountEquals(1)
    }
}
