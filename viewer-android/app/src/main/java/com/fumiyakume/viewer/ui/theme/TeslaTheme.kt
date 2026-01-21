package com.fumiyakume.viewer.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable

/**
 * Tesla Dashboard UI テーマ
 *
 * Material3をベースにTeslaカラースキームを適用
 */

private val TeslaDarkColorScheme = darkColorScheme(
    primary = TeslaColors.Accent,
    onPrimary = TeslaColors.TextPrimary,
    primaryContainer = TeslaColors.Surface,
    onPrimaryContainer = TeslaColors.TextPrimary,
    secondary = TeslaColors.StatusOrange,
    onSecondary = TeslaColors.TextPrimary,
    tertiary = TeslaColors.StatusGreen,
    onTertiary = TeslaColors.TextPrimary,
    background = TeslaColors.Background,
    onBackground = TeslaColors.TextPrimary,
    surface = TeslaColors.Surface,
    onSurface = TeslaColors.TextPrimary,
    surfaceVariant = TeslaColors.SurfaceElevated,
    onSurfaceVariant = TeslaColors.TextSecondary,
    error = TeslaColors.StatusRed,
    onError = TeslaColors.TextPrimary,
    outline = TeslaColors.GlassBorder,
    outlineVariant = TeslaColors.TextTertiary
)

@Suppress("UNUSED_PARAMETER")
@Composable
fun TeslaTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    // Tesla UIは常にダークテーマ（darkThemeパラメータは将来の拡張用に保持）
    val colorScheme = TeslaDarkColorScheme
    val teslaColors = TeslaColorScheme()
    val teslaTypography = TeslaTypography()
    val teslaAnimation = TeslaAnimation()

    CompositionLocalProvider(
        LocalTeslaColors provides teslaColors,
        LocalTeslaTypography provides teslaTypography,
        LocalTeslaAnimation provides teslaAnimation
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            content = content
        )
    }
}

/**
 * Teslaテーマへのアクセスを提供するオブジェクト
 */
object TeslaTheme {
    val colors: TeslaColorScheme
        @Composable
        @ReadOnlyComposable
        get() = LocalTeslaColors.current

    val typography: TeslaTypography
        @Composable
        @ReadOnlyComposable
        get() = LocalTeslaTypography.current

    val animation: TeslaAnimation
        @Composable
        @ReadOnlyComposable
        get() = LocalTeslaAnimation.current
}
