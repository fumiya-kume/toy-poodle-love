package com.fumiyakume.viewer.ui.theme

import androidx.compose.animation.core.TweenSpec
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TeslaThemeModelsTest {

    @Test
    fun teslaColorScheme_defaults_matchTeslaColors() {
        val scheme = TeslaColorScheme()

        assertEquals(TeslaColors.Background, scheme.background)
        assertEquals(TeslaColors.Surface, scheme.surface)
        assertEquals(TeslaColors.SurfaceElevated, scheme.surfaceElevated)
        assertEquals(TeslaColors.Accent, scheme.accent)
        assertEquals(TeslaColors.StatusGreen, scheme.statusGreen)
        assertEquals(TeslaColors.StatusOrange, scheme.statusOrange)
        assertEquals(TeslaColors.StatusRed, scheme.statusRed)
        assertEquals(TeslaColors.TextPrimary, scheme.textPrimary)
        assertEquals(TeslaColors.TextSecondary, scheme.textSecondary)
        assertEquals(TeslaColors.TextTertiary, scheme.textTertiary)
        assertEquals(TeslaColors.TextDisabled, scheme.textDisabled)
        assertEquals(TeslaColors.GlassBackground, scheme.glassBackground)
        assertEquals(TeslaColors.GlassBackgroundElevated, scheme.glassBackgroundElevated)
        assertEquals(TeslaColors.GlassBorder, scheme.glassBorder)
        assertEquals(TeslaColors.MainVideoColor, scheme.mainVideoColor)
        assertEquals(TeslaColors.OverlayVideoColor, scheme.overlayVideoColor)
    }

    @Test
    fun teslaAnimation_buildsTweenSpecs_withConfiguredDurations() {
        val animation = TeslaAnimation(standardDurationMs = 123, quickDurationMs = 45)

        val standard = animation.standardSpec<Float>()
        val quick = animation.quickSpec<Float>()

        assertTrue(standard is TweenSpec<*>)
        assertTrue(quick is TweenSpec<*>)
        assertEquals(123, (standard as TweenSpec<*>).durationMillis)
        assertEquals(45, (quick as TweenSpec<*>).durationMillis)
    }

    @Test
    fun teslaTypography_hasExpectedDefaults_forARepresentativeStyle() {
        val typography = TeslaTypography()

        assertEquals(FontWeight.Bold, typography.displayLarge.fontWeight)
        assertEquals(48.sp, typography.displayLarge.fontSize)
        assertEquals(56.sp, typography.displayLarge.lineHeight)
    }
}

