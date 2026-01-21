package com.fumiyakume.viewer.ui.videoplayer

import android.net.Uri
import androidx.media3.common.Player
import io.mockk.mockk
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VideoPlayerUiStateTest {

    @Test
    fun computedFlags_reflectUris() {
        val mainUri = mockk<Uri>()
        val overlayUri = mockk<Uri>()
        val state = VideoPlayerUiState(
            mainVideoUri = mainUri,
            overlayVideoUri = overlayUri
        )

        assertTrue(state.hasMainVideo)
        assertTrue(state.hasOverlayVideo)

        val emptyState = VideoPlayerUiState()
        assertFalse(emptyState.hasMainVideo)
        assertFalse(emptyState.hasOverlayVideo)
    }

    @Test
    fun computedFlags_reflectPlaybackStates() {
        val readyState = VideoPlayerUiState(
            mainPlaybackState = Player.STATE_READY,
            overlayPlaybackState = Player.STATE_READY
        )
        assertTrue(readyState.isMainReady)
        assertTrue(readyState.isOverlayReady)

        val idleState = VideoPlayerUiState(
            mainPlaybackState = Player.STATE_IDLE,
            overlayPlaybackState = Player.STATE_BUFFERING
        )
        assertFalse(idleState.isMainReady)
        assertFalse(idleState.isOverlayReady)
    }

    @Test
    fun defaults_areReasonable() {
        val state = VideoPlayerUiState()

        assertEquals(0.5f, state.overlayOpacity, 0.001f)
        assertTrue(state.isOverlayVisible)
        assertTrue(state.areControlsVisible)
    }
}

