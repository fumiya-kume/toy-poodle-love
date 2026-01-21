package com.fumiyakume.viewer.ui.videoplayer

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ビデオプレイヤーの状態を管理するViewModel
 *
 * デュアルビデオ（メイン + オーバーレイ）の再生を独立して管理
 */
@HiltViewModel
class VideoPlayerViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(VideoPlayerUiState())
    val uiState: StateFlow<VideoPlayerUiState> = _uiState.asStateFlow()

    private var mainPlayer: ExoPlayer? = null
    private var overlayPlayer: ExoPlayer? = null
    private var controlHideJob: Job? = null

    // コントロール自動非表示の遅延時間（3秒）
    private val controlHideDelayMs = 3000L

    init {
        initializePlayers()
    }

    private fun initializePlayers() {
        mainPlayer = ExoPlayer.Builder(context).build().apply {
            addListener(object : Player.Listener {
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    _uiState.update { it.copy(isMainPlaying = isPlaying) }
                }

                override fun onPlaybackStateChanged(playbackState: Int) {
                    _uiState.update { it.copy(mainPlaybackState = playbackState) }
                }
            })
        }

        overlayPlayer = ExoPlayer.Builder(context).build().apply {
            addListener(object : Player.Listener {
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    _uiState.update { it.copy(isOverlayPlaying = isPlaying) }
                }

                override fun onPlaybackStateChanged(playbackState: Int) {
                    _uiState.update { it.copy(overlayPlaybackState = playbackState) }
                }
            })
        }
    }

    // region Main Video

    fun setMainVideoUri(uri: Uri) {
        mainPlayer?.apply {
            setMediaItem(MediaItem.fromUri(uri))
            prepare()
        }
        _uiState.update { it.copy(mainVideoUri = uri) }
    }

    fun setMainVideoUrl(url: String) {
        val uri = Uri.parse(url)
        setMainVideoUri(uri)
    }

    fun playMainVideo() {
        mainPlayer?.play()
    }

    fun pauseMainVideo() {
        mainPlayer?.pause()
    }

    fun toggleMainPlayPause() {
        mainPlayer?.let { player ->
            if (player.isPlaying) {
                player.pause()
            } else {
                player.play()
            }
        }
    }

    fun seekMainTo(positionMs: Long) {
        mainPlayer?.seekTo(positionMs)
    }

    // endregion

    // region Overlay Video

    fun setOverlayVideoUri(uri: Uri) {
        overlayPlayer?.apply {
            setMediaItem(MediaItem.fromUri(uri))
            prepare()
        }
        _uiState.update { it.copy(overlayVideoUri = uri) }
    }

    fun setOverlayVideoUrl(url: String) {
        val uri = Uri.parse(url)
        setOverlayVideoUri(uri)
    }

    fun playOverlayVideo() {
        overlayPlayer?.play()
    }

    fun pauseOverlayVideo() {
        overlayPlayer?.pause()
    }

    fun toggleOverlayPlayPause() {
        overlayPlayer?.let { player ->
            if (player.isPlaying) {
                player.pause()
            } else {
                player.play()
            }
        }
    }

    fun seekOverlayTo(positionMs: Long) {
        overlayPlayer?.seekTo(positionMs)
    }

    // endregion

    // region Overlay Settings

    fun setOverlayOpacity(opacity: Float) {
        _uiState.update { it.copy(overlayOpacity = opacity.coerceIn(0f, 1f)) }
    }

    fun toggleOverlayVisibility() {
        _uiState.update { it.copy(isOverlayVisible = !it.isOverlayVisible) }
    }

    // endregion

    // region Controls Visibility

    fun showControls() {
        _uiState.update { it.copy(areControlsVisible = true) }
        scheduleControlHide()
    }

    fun hideControls() {
        _uiState.update { it.copy(areControlsVisible = false) }
    }

    fun toggleControls() {
        if (_uiState.value.areControlsVisible) {
            hideControls()
        } else {
            showControls()
        }
    }

    private fun scheduleControlHide() {
        controlHideJob?.cancel()
        controlHideJob = viewModelScope.launch {
            delay(controlHideDelayMs)
            hideControls()
        }
    }

    // endregion

    // region Player Access

    fun getMainPlayer(): ExoPlayer? = mainPlayer
    fun getOverlayPlayer(): ExoPlayer? = overlayPlayer

    // endregion

    override fun onCleared() {
        super.onCleared()
        mainPlayer?.release()
        overlayPlayer?.release()
        mainPlayer = null
        overlayPlayer = null
    }
}

/**
 * ビデオプレイヤーのUI状態
 */
data class VideoPlayerUiState(
    val mainVideoUri: Uri? = null,
    val overlayVideoUri: Uri? = null,
    val isMainPlaying: Boolean = false,
    val isOverlayPlaying: Boolean = false,
    val mainPlaybackState: Int = Player.STATE_IDLE,
    val overlayPlaybackState: Int = Player.STATE_IDLE,
    val overlayOpacity: Float = 0.5f,
    val isOverlayVisible: Boolean = true,
    val areControlsVisible: Boolean = true
) {
    val hasMainVideo: Boolean get() = mainVideoUri != null
    val hasOverlayVideo: Boolean get() = overlayVideoUri != null
    val isMainReady: Boolean get() = mainPlaybackState == Player.STATE_READY
    val isOverlayReady: Boolean get() = overlayPlaybackState == Player.STATE_READY
}
