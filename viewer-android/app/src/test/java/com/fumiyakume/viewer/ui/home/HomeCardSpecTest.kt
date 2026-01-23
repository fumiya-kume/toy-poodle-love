package com.fumiyakume.viewer.ui.home

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.ui.graphics.Color
import com.fumiyakume.viewer.R
import com.fumiyakume.viewer.ui.theme.TeslaColorScheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HomeCardSpecTest {

    @Test
    fun buildHomeCardSpecs_buildsCardsInExpectedOrder() {
        val colors = TeslaColorScheme(
            accent = Color.Red,
            statusOrange = Color.Green
        )
        var videoClicked = false
        var scenarioClicked = false

        val cards = buildHomeCardSpecs(
            colors = colors,
            onNavigateToVideoPlayer = { videoClicked = true },
            onNavigateToScenarioWriter = { scenarioClicked = true }
        )

        assertEquals(2, cards.size)

        val videoCard = cards[0]
        assertEquals(HomeCardId.VIDEO_PLAYER, videoCard.id)
        assertEquals(Icons.Default.PlayArrow, videoCard.icon)
        assertEquals(R.string.home_video_player_title, videoCard.titleRes)
        assertEquals(R.string.home_video_player_description, videoCard.descriptionRes)
        assertEquals(Color.Red, videoCard.accentColor)
        videoCard.onClick()
        assertTrue(videoClicked)

        val scenarioCard = cards[1]
        assertEquals(HomeCardId.SCENARIO_WRITER, scenarioCard.id)
        assertEquals(Icons.Default.Edit, scenarioCard.icon)
        assertEquals(R.string.home_scenario_writer_title, scenarioCard.titleRes)
        assertEquals(R.string.home_scenario_writer_description, scenarioCard.descriptionRes)
        assertEquals(Color.Green, scenarioCard.accentColor)
        scenarioCard.onClick()
        assertTrue(scenarioClicked)
    }
}
