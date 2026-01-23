package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import com.fumiyakume.viewer.ui.theme.TeslaColors
import org.junit.Assert.assertEquals
import org.junit.Test

class TeslaAlertCardTest {

    @Test
    fun alertColors_returnsExpectedColorsForInfo() {
        val colors = alertColors(TeslaAlertVariant.Info)

        assertEquals(TeslaColors.Accent.copy(alpha = 0.1f), colors.backgroundColor)
        assertEquals(TeslaColors.Accent.copy(alpha = 0.3f), colors.borderColor)
        assertEquals(TeslaColors.Accent, colors.iconTint)
    }

    @Test
    fun alertColors_returnsExpectedColorsForError() {
        val colors = alertColors(TeslaAlertVariant.Error)

        assertEquals(TeslaColors.StatusRed.copy(alpha = 0.1f), colors.backgroundColor)
        assertEquals(TeslaColors.StatusRed.copy(alpha = 0.3f), colors.borderColor)
        assertEquals(TeslaColors.StatusRed, colors.iconTint)
    }

    @Test
    fun alertDefaultIcon_returnsExpectedIcons() {
        assertEquals(Icons.Default.Info, alertDefaultIcon(TeslaAlertVariant.Info))
        assertEquals(Icons.Default.CheckCircle, alertDefaultIcon(TeslaAlertVariant.Success))
        assertEquals(Icons.Default.Warning, alertDefaultIcon(TeslaAlertVariant.Warning))
        assertEquals(Icons.Default.Warning, alertDefaultIcon(TeslaAlertVariant.Error))
    }
}
