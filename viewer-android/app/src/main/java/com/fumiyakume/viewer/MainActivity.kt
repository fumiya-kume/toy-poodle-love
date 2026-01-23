package com.fumiyakume.viewer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.fumiyakume.viewer.core.navigation.ViewerNavigation
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * メインアクティビティ
 *
 * Single Activity アーキテクチャのエントリーポイント
 * Jetpack Compose Navigationで画面遷移を管理
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (shouldEnableEdgeToEdge()) {
            enableEdgeToEdge()
        }
        setContent {
            TeslaTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = appBackgroundColor()
                ) {
                    ViewerNavigation()
                }
            }
        }
    }
}

internal fun shouldEnableEdgeToEdge(): Boolean = true

internal fun appBackgroundColor() = TeslaColors.Background
