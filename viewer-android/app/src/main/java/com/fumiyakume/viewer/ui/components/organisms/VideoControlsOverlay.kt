package com.fumiyakume.viewer.ui.components.organisms

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.fumiyakume.viewer.ui.components.molecules.TeslaIconButton
import com.fumiyakume.viewer.ui.components.molecules.TeslaIconButtonSize
import com.fumiyakume.viewer.ui.components.molecules.TeslaIconButtonVariant
import com.fumiyakume.viewer.ui.components.molecules.TeslaSlider
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme
import kotlinx.coroutines.delay
import java.util.concurrent.TimeUnit

/**
 * ビデオ再生コントロールオーバーレイ
 *
 * 再生/一時停止、シークバー、透明度調整を提供
 */
@Composable
fun VideoControlsOverlay(
    isVisible: Boolean,
    isPlaying: Boolean,
    currentPositionMs: Long,
    durationMs: Long,
    overlayOpacity: Float,
    onNavigateBack: () -> Unit,
    onPlayPauseClick: () -> Unit,
    onSeek: (Long) -> Unit,
    onOpacityChange: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = isVisible,
        enter = fadeIn(),
        exit = fadeOut(),
        modifier = modifier
    ) {
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            // Top gradient bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                TeslaColors.Background.copy(alpha = 0.8f),
                                Color.Transparent
                            )
                        )
                    )
                    .align(Alignment.TopCenter)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "戻る",
                            tint = TeslaColors.TextPrimary
                        )
                    }
                }
            }

            // Center play/pause button
            TeslaIconButton(
                icon = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                contentDescription = if (isPlaying) "一時停止" else "再生",
                onClick = onPlayPauseClick,
                size = TeslaIconButtonSize.Large,
                variant = TeslaIconButtonVariant.Glass,
                modifier = Modifier.align(Alignment.Center)
            )

            // Bottom control bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                TeslaColors.Background.copy(alpha = 0.8f)
                            )
                        )
                    )
                    .align(Alignment.BottomCenter)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Progress bar
                    VideoProgressBar(
                        currentPositionMs = currentPositionMs,
                        durationMs = durationMs,
                        onSeek = onSeek
                    )

                    // Opacity slider
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            text = "オーバーレイ透明度",
                            style = TeslaTheme.typography.labelMedium,
                            color = TeslaColors.TextSecondary
                        )

                        TeslaSlider(
                            value = overlayOpacity,
                            onValueChange = onOpacityChange,
                            showValue = true,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun VideoProgressBar(
    currentPositionMs: Long,
    durationMs: Long,
    onSeek: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val progress = if (durationMs > 0) {
        (currentPositionMs.toFloat() / durationMs).coerceIn(0f, 1f)
    } else {
        0f
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Slider(
            value = progress,
            onValueChange = { newProgress ->
                onSeek((newProgress * durationMs).toLong())
            },
            colors = SliderDefaults.colors(
                thumbColor = TeslaColors.Accent,
                activeTrackColor = TeslaColors.Accent,
                inactiveTrackColor = TeslaColors.GlassBorder
            ),
            modifier = Modifier.fillMaxWidth()
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = formatDuration(currentPositionMs),
                style = TeslaTheme.typography.labelSmall,
                color = TeslaColors.TextSecondary
            )

            Text(
                text = formatDuration(durationMs),
                style = TeslaTheme.typography.labelSmall,
                color = TeslaColors.TextSecondary
            )
        }
    }
}

/**
 * ExoPlayerの再生位置を監視するComposable
 */
@Composable
fun rememberPlayerPosition(player: ExoPlayer?): Pair<Long, Long> {
    var currentPosition by remember { mutableLongStateOf(0L) }
    var duration by remember { mutableLongStateOf(0L) }

    LaunchedEffect(player) {
        while (player != null) {
            currentPosition = player.currentPosition
            duration = player.duration.coerceAtLeast(0L)
            delay(500) // 500ms間隔で更新
        }
    }

    return currentPosition to duration
}

private fun formatDuration(ms: Long): String {
    if (ms < 0) return "0:00"
    val hours = TimeUnit.MILLISECONDS.toHours(ms)
    val minutes = TimeUnit.MILLISECONDS.toMinutes(ms) % 60
    val seconds = TimeUnit.MILLISECONDS.toSeconds(ms) % 60

    return if (hours > 0) {
        String.format("%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format("%d:%02d", minutes, seconds)
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun VideoControlsOverlayPreview() {
    TeslaTheme {
        VideoControlsOverlay(
            isVisible = true,
            isPlaying = false,
            currentPositionMs = 30000,
            durationMs = 180000,
            overlayOpacity = 0.5f,
            onNavigateBack = {},
            onPlayPauseClick = {},
            onSeek = {},
            onOpacityChange = {},
            modifier = Modifier.fillMaxSize()
        )
    }
}
