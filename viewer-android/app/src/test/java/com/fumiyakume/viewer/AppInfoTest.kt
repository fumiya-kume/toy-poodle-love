package com.fumiyakume.viewer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AppInfoTest {

    @Test
    fun appTitle_usesNameWhenVersionMissing() {
        assertEquals("Viewer", AppInfo.appTitle(null))
        assertEquals("Viewer", AppInfo.appTitle(""))
    }

    @Test
    fun appTitle_includesVersionWhenProvided() {
        assertEquals("Viewer v1.0", AppInfo.appTitle("1.0"))
    }

    @Test
    fun isValidRoute_rejectsBlank() {
        assertTrue(AppInfo.isValidRoute("home"))
        assertFalse(AppInfo.isValidRoute(""))
    }
}
