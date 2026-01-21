package com.fumiyakume.viewer.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Tesla Dashboard UI カラーパレット
 *
 * macOS版からの正確なカラー値を移植
 * ダークテーマ専用で、高コントラスト・高視認性を実現
 */
object TeslaColors {
    // Background Colors
    val Background = Color(0xFF141416)
    val Surface = Color(0xFF1E1E22)
    val SurfaceElevated = Color(0xFF28282C)

    // Accent Colors
    val Accent = Color(0xFF3399FF)        // Tesla Blue
    val StatusGreen = Color(0xFF4DD966)
    val StatusOrange = Color(0xFFFF9933)
    val StatusRed = Color(0xFFF24D4D)

    // Text Colors
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB3B3B3)
    val TextTertiary = Color(0xFF808080)
    val TextDisabled = Color(0xFF4D4D4D)

    // Glassmorphism
    val GlassBackground = Color.White.copy(alpha = 0.08f)
    val GlassBackgroundElevated = Color.White.copy(alpha = 0.16f)
    val GlassBorder = Color.White.copy(alpha = 0.12f)

    // Video Player Specific
    val MainVideoColor = Accent
    val OverlayVideoColor = StatusOrange
}

/**
 * テーマで使用するカラースキーム
 */
@Immutable
data class TeslaColorScheme(
    val background: Color = TeslaColors.Background,
    val surface: Color = TeslaColors.Surface,
    val surfaceElevated: Color = TeslaColors.SurfaceElevated,
    val accent: Color = TeslaColors.Accent,
    val statusGreen: Color = TeslaColors.StatusGreen,
    val statusOrange: Color = TeslaColors.StatusOrange,
    val statusRed: Color = TeslaColors.StatusRed,
    val textPrimary: Color = TeslaColors.TextPrimary,
    val textSecondary: Color = TeslaColors.TextSecondary,
    val textTertiary: Color = TeslaColors.TextTertiary,
    val textDisabled: Color = TeslaColors.TextDisabled,
    val glassBackground: Color = TeslaColors.GlassBackground,
    val glassBackgroundElevated: Color = TeslaColors.GlassBackgroundElevated,
    val glassBorder: Color = TeslaColors.GlassBorder,
    val mainVideoColor: Color = TeslaColors.MainVideoColor,
    val overlayVideoColor: Color = TeslaColors.OverlayVideoColor
)

val LocalTeslaColors = staticCompositionLocalOf { TeslaColorScheme() }
