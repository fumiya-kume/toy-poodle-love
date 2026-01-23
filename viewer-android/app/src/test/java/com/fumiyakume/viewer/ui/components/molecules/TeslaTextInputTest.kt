package com.fumiyakume.viewer.ui.components.molecules

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TeslaTextInputTest {

    @Test
    fun shouldShowPlaceholder_returnsTrueWhenNotBlank() {
        assertTrue(shouldShowPlaceholder("placeholder"))
        assertFalse(shouldShowPlaceholder(""))
    }

    @Test
    fun resolveErrorMessage_returnsMessageWhenErrorAndNotBlank() {
        assertEquals("error", resolveErrorMessage(isError = true, errorMessage = "error"))
        assertNull(resolveErrorMessage(isError = true, errorMessage = ""))
        assertNull(resolveErrorMessage(isError = false, errorMessage = "error"))
    }
}
