package com.fumiyakume.viewer.ui.components.molecules

import com.fumiyakume.viewer.ui.theme.TeslaColors
import org.junit.Assert.assertEquals
import org.junit.Test

class TeslaToggleTest {

    @Test
    fun toggleTrackColor_returnsAccentWhenChecked() {
        assertEquals(TeslaColors.Accent, toggleTrackColor(true))
    }

    @Test
    fun toggleTrackColor_returnsGlassBackgroundWhenUnchecked() {
        assertEquals(TeslaColors.GlassBackground, toggleTrackColor(false))
    }

    @Test
    fun toggleThumbOffset_returnsExpectedOffsets() {
        assertEquals(20f, toggleThumbOffset(true).value)
        assertEquals(0f, toggleThumbOffset(false).value)
    }

    @Test
    fun toggleThumbColor_returnsDisabledColorWhenNotEnabled() {
        assertEquals(TeslaColors.TextTertiary, toggleThumbColor(false))
    }
}
