package com.fumiyakume.viewer.ui.videoplayer

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Link
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.media3.ui.PlayerView
import com.fumiyakume.viewer.ui.components.molecules.TeslaAlertCard
import com.fumiyakume.viewer.ui.components.molecules.TeslaAlertVariant
import com.fumiyakume.viewer.ui.components.molecules.TeslaIconButton
import com.fumiyakume.viewer.ui.components.molecules.TeslaIconButtonVariant
import com.fumiyakume.viewer.ui.components.organisms.VideoControlsOverlay
import com.fumiyakume.viewer.ui.components.organisms.rememberPlayerPosition
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * ビデオプレイヤー画面
 *
 * デュアルビデオ再生（メイン + オーバーレイ）をサポート
 */
@Composable
fun VideoPlayerScreen(
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: VideoPlayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val mainPlayer = viewModel.getMainPlayer()
    val overlayPlayer = viewModel.getOverlayPlayer()

    val (mainPosition, mainDuration) = rememberPlayerPosition(mainPlayer)

    var showUrlDialog by remember { mutableStateOf<VideoType?>(null) }

    // File picker launchers
    val mainVideoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.setMainVideoUri(it) }
    }

    val overlayVideoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.setOverlayVideoUri(it) }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(TeslaColors.Background)
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) {
                viewModel.toggleControls()
            }
    ) {
        if (uiState.hasMainVideo) {
            // Main video layer
            AndroidView(
                factory = { context ->
                    PlayerView(context).apply {
                        player = mainPlayer
                        useController = false
                    }
                },
                modifier = Modifier.fillMaxSize()
            )

            // Overlay video layer
            if (uiState.hasOverlayVideo && uiState.isOverlayVisible) {
                AndroidView(
                    factory = { context ->
                        PlayerView(context).apply {
                            player = overlayPlayer
                            useController = false
                        }
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .alpha(uiState.overlayOpacity)
                )
            }

            // Controls overlay
            VideoControlsOverlay(
                isVisible = uiState.areControlsVisible,
                isPlaying = uiState.isMainPlaying,
                currentPositionMs = mainPosition,
                durationMs = mainDuration,
                overlayOpacity = uiState.overlayOpacity,
                onNavigateBack = onNavigateBack,
                onPlayPauseClick = { viewModel.toggleMainPlayPause() },
                onSeek = { viewModel.seekMainTo(it) },
                onOpacityChange = { viewModel.setOverlayOpacity(it) },
                modifier = Modifier.fillMaxSize()
            )
        } else {
            // No video selected - show selection UI
            VideoSelectionScreen(
                onSelectMainFile = { mainVideoPickerLauncher.launch("video/*") },
                onSelectOverlayFile = { overlayVideoPickerLauncher.launch("video/*") },
                onSelectMainUrl = { showUrlDialog = VideoType.Main },
                onSelectOverlayUrl = { showUrlDialog = VideoType.Overlay },
                onNavigateBack = onNavigateBack,
                hasOverlayVideo = uiState.hasOverlayVideo,
                modifier = Modifier.fillMaxSize()
            )
        }
    }

    // URL input dialog
    showUrlDialog?.let { videoType ->
        UrlInputDialog(
            videoType = videoType,
            onDismiss = { showUrlDialog = null },
            onConfirm = { url ->
                when (videoType) {
                    VideoType.Main -> viewModel.setMainVideoUrl(url)
                    VideoType.Overlay -> viewModel.setOverlayVideoUrl(url)
                }
                showUrlDialog = null
            }
        )
    }
}

@Suppress("UNUSED_PARAMETER")
@Composable
private fun VideoSelectionScreen(
    onSelectMainFile: () -> Unit,
    onSelectOverlayFile: () -> Unit,
    onSelectMainUrl: () -> Unit,
    onSelectOverlayUrl: () -> Unit,
    onNavigateBack: () -> Unit,
    hasOverlayVideo: Boolean, // 将来の拡張用に保持
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        TeslaAlertCard(
            message = "ビデオファイルを選択するか、URLを入力してください",
            variant = TeslaAlertVariant.Info,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Main video selection
        Text(
            text = "メインビデオ",
            style = TeslaTheme.typography.titleMedium,
            color = TeslaColors.TextPrimary
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            VideoSelectionButton(
                icon = Icons.Default.Add,
                text = "ファイルを選択",
                onClick = onSelectMainFile
            )

            VideoSelectionButton(
                icon = Icons.Default.Link,
                text = "URLを入力",
                onClick = onSelectMainUrl
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Overlay video selection
        Text(
            text = "オーバーレイビデオ（オプション）",
            style = TeslaTheme.typography.titleMedium,
            color = TeslaColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            VideoSelectionButton(
                icon = Icons.Default.Add,
                text = "ファイルを選択",
                onClick = onSelectOverlayFile
            )

            VideoSelectionButton(
                icon = Icons.Default.Link,
                text = "URLを入力",
                onClick = onSelectOverlayUrl
            )
        }

        Spacer(modifier = Modifier.height(48.dp))

        TextButton(onClick = onNavigateBack) {
            Text(
                text = "ホームに戻る",
                color = TeslaColors.TextSecondary
            )
        }
    }
}

@Composable
private fun VideoSelectionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = TeslaColors.GlassBackground
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier
    ) {
        TeslaIconButton(
            icon = icon,
            contentDescription = null,
            onClick = onClick,
            variant = TeslaIconButtonVariant.Primary
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            color = TeslaColors.TextPrimary
        )
    }
}

@Composable
private fun UrlInputDialog(
    videoType: VideoType,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var url by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = TeslaColors.Surface,
        title = {
            Text(
                text = when (videoType) {
                    VideoType.Main -> "メインビデオURL"
                    VideoType.Overlay -> "オーバーレイビデオURL"
                },
                color = TeslaColors.TextPrimary
            )
        },
        text = {
            OutlinedTextField(
                value = url,
                onValueChange = { url = it },
                label = { Text("URL") },
                placeholder = { Text("https://example.com/video.mp4") },
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = TeslaColors.Accent,
                    unfocusedBorderColor = TeslaColors.GlassBorder,
                    focusedTextColor = TeslaColors.TextPrimary,
                    unfocusedTextColor = TeslaColors.TextPrimary,
                    focusedLabelColor = TeslaColors.Accent,
                    unfocusedLabelColor = TeslaColors.TextSecondary
                ),
                modifier = Modifier.fillMaxWidth()
            )
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(url) },
                enabled = url.isNotBlank()
            ) {
                Text("開く", color = TeslaColors.Accent)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("キャンセル", color = TeslaColors.TextSecondary)
            }
        }
    )
}

private enum class VideoType {
    Main,
    Overlay
}

@Preview(
    showBackground = true,
    widthDp = 1024,
    heightDp = 768
)
@Composable
private fun VideoSelectionScreenPreview() {
    TeslaTheme {
        VideoSelectionScreen(
            onSelectMainFile = {},
            onSelectOverlayFile = {},
            onSelectMainUrl = {},
            onSelectOverlayUrl = {},
            onNavigateBack = {},
            hasOverlayVideo = false
        )
    }
}
