package com.fumiyakume.viewer

import com.fumiyakume.viewer.ui.theme.TeslaColors
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MainActivityTest {

    @Test
    fun shouldEnableEdgeToEdge_returnsTrue() {
        assertTrue(shouldEnableEdgeToEdge())
    }

    @Test
    fun appBackgroundColor_returnsTeslaBackground() {
        assertEquals(TeslaColors.Background, appBackgroundColor())
    }
}
