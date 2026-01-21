package com.fumiyakume.viewer.ui.videoplayer

import android.net.Uri
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.fumiyakume.viewer.test.MainDispatcherRule
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.runs
import io.mockk.slot
import io.mockk.verify
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class VideoPlayerViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: VideoPlayerViewModel
    private lateinit var mainPlayer: ExoPlayer
    private lateinit var overlayPlayer: ExoPlayer
    private lateinit var mainListener: Player.Listener
    private lateinit var overlayListener: Player.Listener

    @Before
    fun setup() {
        mainPlayer = mockk(relaxed = true)
        overlayPlayer = mockk(relaxed = true)

        val mainListenerSlot = slot<Player.Listener>()
        val overlayListenerSlot = slot<Player.Listener>()
        every { mainPlayer.addListener(capture(mainListenerSlot)) } just runs
        every { overlayPlayer.addListener(capture(overlayListenerSlot)) } just runs

        val exoPlayerFactory = mockk<ExoPlayerFactory>()
        every { exoPlayerFactory.create() } returnsMany listOf(mainPlayer, overlayPlayer)
        viewModel = VideoPlayerViewModel(exoPlayerFactory)

        mainListener = mainListenerSlot.captured
        overlayListener = overlayListenerSlot.captured
    }

    @Test
    fun playersAreExposed_andListenersUpdateUiState() {
        assertSame(mainPlayer, viewModel.getMainPlayer())
        assertSame(overlayPlayer, viewModel.getOverlayPlayer())

        mainListener.onIsPlayingChanged(true)
        assertTrue(viewModel.uiState.value.isMainPlaying)

        mainListener.onPlaybackStateChanged(Player.STATE_READY)
        assertEquals(Player.STATE_READY, viewModel.uiState.value.mainPlaybackState)

        overlayListener.onIsPlayingChanged(true)
        assertTrue(viewModel.uiState.value.isOverlayPlaying)

        overlayListener.onPlaybackStateChanged(Player.STATE_BUFFERING)
        assertEquals(Player.STATE_BUFFERING, viewModel.uiState.value.overlayPlaybackState)
    }

    @Test
    fun setMainVideoUri_setsMediaItem_prepares_andUpdatesState() {
        val uri = mockk<Uri>()

        viewModel.setMainVideoUri(uri)

        verify(exactly = 1) { mainPlayer.setMediaItem(any()) }
        verify(exactly = 1) { mainPlayer.prepare() }
        assertSame(uri, viewModel.uiState.value.mainVideoUri)
    }

    @Test
    fun setOverlayVideoUri_setsMediaItem_prepares_andUpdatesState() {
        val uri = mockk<Uri>()

        viewModel.setOverlayVideoUri(uri)

        verify(exactly = 1) { overlayPlayer.setMediaItem(any()) }
        verify(exactly = 1) { overlayPlayer.prepare() }
        assertSame(uri, viewModel.uiState.value.overlayVideoUri)
    }

    @Test
    fun toggleMainPlayPause_pausesWhenPlaying_andPlaysWhenPaused() {
        every { mainPlayer.isPlaying } returns true

        viewModel.toggleMainPlayPause()
        verify(exactly = 1) { mainPlayer.pause() }
        verify(exactly = 0) { mainPlayer.play() }

        every { mainPlayer.isPlaying } returns false

        viewModel.toggleMainPlayPause()
        verify(exactly = 1) { mainPlayer.play() }
    }

    @Test
    fun toggleOverlayPlayPause_pausesWhenPlaying_andPlaysWhenPaused() {
        every { overlayPlayer.isPlaying } returns true

        viewModel.toggleOverlayPlayPause()
        verify(exactly = 1) { overlayPlayer.pause() }
        verify(exactly = 0) { overlayPlayer.play() }

        every { overlayPlayer.isPlaying } returns false

        viewModel.toggleOverlayPlayPause()
        verify(exactly = 1) { overlayPlayer.play() }
    }

    @Test
    fun seekMainTo_callsPlayer() {
        viewModel.seekMainTo(1234L)

        verify(exactly = 1) { mainPlayer.seekTo(1234L) }
    }

    @Test
    fun seekOverlayTo_callsPlayer() {
        viewModel.seekOverlayTo(5678L)

        verify(exactly = 1) { overlayPlayer.seekTo(5678L) }
    }

    @Test
    fun overlayOpacity_isClampedToValidRange() {
        viewModel.setOverlayOpacity(-1f)
        assertEquals(0f, viewModel.uiState.value.overlayOpacity)

        viewModel.setOverlayOpacity(2f)
        assertEquals(1f, viewModel.uiState.value.overlayOpacity)
    }

    @Test
    fun toggleOverlayVisibility_flipsFlag() {
        assertTrue(viewModel.uiState.value.isOverlayVisible)

        viewModel.toggleOverlayVisibility()
        assertFalse(viewModel.uiState.value.isOverlayVisible)

        viewModel.toggleOverlayVisibility()
        assertTrue(viewModel.uiState.value.isOverlayVisible)
    }

    @Test
    fun showControls_schedulesAutoHide_afterDelay() = runTest(mainDispatcherRule.dispatcher) {
        viewModel.hideControls()
        assertFalse(viewModel.uiState.value.areControlsVisible)

        viewModel.showControls()
        assertTrue(viewModel.uiState.value.areControlsVisible)

        advanceTimeBy(2999)
        runCurrent()
        assertTrue(viewModel.uiState.value.areControlsVisible)

        advanceTimeBy(1)
        runCurrent()
        assertFalse(viewModel.uiState.value.areControlsVisible)
    }

    @Test
    fun showControls_resetsAutoHideTimer_whenCalledAgain() = runTest(mainDispatcherRule.dispatcher) {
        viewModel.hideControls()
        viewModel.showControls()

        advanceTimeBy(2000)
        runCurrent()
        assertTrue(viewModel.uiState.value.areControlsVisible)

        viewModel.showControls()

        advanceTimeBy(2000)
        runCurrent()
        assertTrue(viewModel.uiState.value.areControlsVisible)

        advanceTimeBy(1000)
        runCurrent()
        assertFalse(viewModel.uiState.value.areControlsVisible)
    }

    @Test
    fun onCleared_releasesPlayers_andClearsReferences() {
        val method = VideoPlayerViewModel::class.java.getDeclaredMethod("onCleared").apply {
            isAccessible = true
        }
        method.invoke(viewModel)

        verify(exactly = 1) { mainPlayer.release() }
        verify(exactly = 1) { overlayPlayer.release() }
        assertNull(viewModel.getMainPlayer())
        assertNull(viewModel.getOverlayPlayer())
    }
}
