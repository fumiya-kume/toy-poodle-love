package com.fumiyakume.viewer.core.navigation

import org.junit.Assert.assertEquals
import org.junit.Test

class ViewerNavigationTest {

    @Test
    fun viewerScreenRoutes_returnsRoutesInOrder() {
        val routes = viewerScreenRoutes()

        assertEquals(
            listOf("home", "video_player", "scenario_writer", "settings"),
            routes
        )
    }
}
