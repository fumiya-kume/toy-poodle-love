package com.fumiyakume.viewer.core.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.fumiyakume.viewer.ui.home.HomeScreen
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioWriterScreen
import com.fumiyakume.viewer.ui.settings.SettingsScreen
import com.fumiyakume.viewer.ui.videoplayer.VideoPlayerScreen

/**
 * ナビゲーションルート定義
 */
sealed class Screen(val route: String) {
    data object Home : Screen("home")
    data object VideoPlayer : Screen("video_player")
    data object ScenarioWriter : Screen("scenario_writer")
    data object Settings : Screen("settings")
}

internal fun viewerScreenRoutes(): List<String> = listOf(
    Screen.Home.route,
    Screen.VideoPlayer.route,
    Screen.ScenarioWriter.route,
    Screen.Settings.route
)

/**
 * メインナビゲーションコンポーザブル
 *
 * Single Activity + Jetpack Compose Navigationで画面遷移を管理
 */
@Composable
fun ViewerNavigation(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToVideoPlayer = {
                    navController.navigate(Screen.VideoPlayer.route)
                },
                onNavigateToScenarioWriter = {
                    navController.navigate(Screen.ScenarioWriter.route)
                },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                }
            )
        }

        composable(Screen.VideoPlayer.route) {
            VideoPlayerScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.ScenarioWriter.route) {
            ScenarioWriterScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
