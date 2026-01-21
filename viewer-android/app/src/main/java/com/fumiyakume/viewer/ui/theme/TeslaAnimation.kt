package com.fumiyakume.viewer.ui.theme

import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * Tesla Dashboard UI アニメーション設定
 *
 * macOS版からの正確なアニメーション時間を移植
 */
@Immutable
data class TeslaAnimation(
    /** 標準アニメーション (300ms easeInOut) */
    val standardDurationMs: Int = 300,

    /** クイックアニメーション (200ms easeInOut) */
    val quickDurationMs: Int = 200,

    /** コントロール自動非表示のデフォルト時間 (3秒) */
    val controlHideDelayMs: Long = 3000L
) {
    /** 標準アニメーションSpec */
    fun <T> standardSpec(): AnimationSpec<T> = tween(durationMillis = standardDurationMs)

    /** クイックアニメーションSpec */
    fun <T> quickSpec(): AnimationSpec<T> = tween(durationMillis = quickDurationMs)
}

val LocalTeslaAnimation = staticCompositionLocalOf { TeslaAnimation() }
