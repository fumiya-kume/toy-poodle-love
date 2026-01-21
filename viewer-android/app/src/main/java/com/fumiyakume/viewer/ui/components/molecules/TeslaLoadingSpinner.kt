package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Tesla UIスタイルのローディングスピナー
 *
 * フルスクリーンオーバーレイまたはインラインで使用可能
 */
@Composable
fun TeslaLoadingSpinner(
    modifier: Modifier = Modifier,
    size: Dp = 48.dp,
    message: String? = null
) {
    val infiniteTransition = rememberInfiniteTransition(label = "loadingTransition")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        CircularProgressIndicator(
            modifier = Modifier
                .size(size)
                .rotate(rotation),
            color = TeslaColors.Accent,
            trackColor = TeslaColors.GlassBackground,
            strokeWidth = 4.dp,
            strokeCap = StrokeCap.Round
        )

        if (message != null) {
            Text(
                text = message,
                style = TeslaTheme.typography.bodyMedium,
                color = TeslaColors.TextSecondary
            )
        }
    }
}

/**
 * フルスクリーンローディングオーバーレイ
 */
@Composable
fun TeslaLoadingOverlay(
    isLoading: Boolean,
    message: String? = null,
    modifier: Modifier = Modifier
) {
    if (isLoading) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .background(TeslaColors.Background.copy(alpha = 0.8f)),
            contentAlignment = Alignment.Center
        ) {
            TeslaLoadingSpinner(
                size = 64.dp,
                message = message
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaLoadingSpinnerPreview() {
    TeslaTheme {
        Box(
            modifier = Modifier
                .size(200.dp)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            TeslaLoadingSpinner(
                message = "読み込み中..."
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaLoadingOverlayPreview() {
    TeslaTheme {
        TeslaLoadingOverlay(
            isLoading = true,
            message = "生成中...",
            modifier = Modifier.size(300.dp)
        )
    }
}
