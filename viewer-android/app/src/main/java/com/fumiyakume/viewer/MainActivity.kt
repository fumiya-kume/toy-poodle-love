package com.fumiyakume.viewer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.fumiyakume.viewer.core.navigation.ViewerNavigation
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
        enableEdgeToEdge()
        setContent {
            TeslaTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = TeslaTheme.colors.background
                ) {
                    ViewerNavigation()
                }
            }
        }
    }
}
