package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Tesla UIスタイルのアラートカード
 *
 * 情報、成功、警告、エラーの4種類のバリアントをサポート
 */
@Composable
fun TeslaAlertCard(
    message: String,
    variant: TeslaAlertVariant,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null
) {
    val (backgroundColor, borderColor, iconTint) = when (variant) {
        TeslaAlertVariant.Info -> Triple(
            TeslaColors.Accent.copy(alpha = 0.1f),
            TeslaColors.Accent.copy(alpha = 0.3f),
            TeslaColors.Accent
        )
        TeslaAlertVariant.Success -> Triple(
            TeslaColors.StatusGreen.copy(alpha = 0.1f),
            TeslaColors.StatusGreen.copy(alpha = 0.3f),
            TeslaColors.StatusGreen
        )
        TeslaAlertVariant.Warning -> Triple(
            TeslaColors.StatusOrange.copy(alpha = 0.1f),
            TeslaColors.StatusOrange.copy(alpha = 0.3f),
            TeslaColors.StatusOrange
        )
        TeslaAlertVariant.Error -> Triple(
            TeslaColors.StatusRed.copy(alpha = 0.1f),
            TeslaColors.StatusRed.copy(alpha = 0.3f),
            TeslaColors.StatusRed
        )
    }

    val defaultIcon = when (variant) {
        TeslaAlertVariant.Info -> Icons.Default.Info
        TeslaAlertVariant.Success -> Icons.Default.CheckCircle
        TeslaAlertVariant.Warning -> Icons.Default.Warning
        TeslaAlertVariant.Error -> Icons.Default.Warning
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(backgroundColor)
            .border(
                width = 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(12.dp)
            )
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon ?: defaultIcon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(24.dp)
        )

        Text(
            text = message,
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )
    }
}

/**
 * TeslaAlertCardのバリアント
 */
enum class TeslaAlertVariant {
    Info,
    Success,
    Warning,
    Error
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaAlertCardInfoPreview() {
    TeslaTheme {
        TeslaAlertCard(
            message = "ビデオファイルを選択してください",
            variant = TeslaAlertVariant.Info,
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaAlertCardSuccessPreview() {
    TeslaTheme {
        TeslaAlertCard(
            message = "シナリオの生成が完了しました",
            variant = TeslaAlertVariant.Success,
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaAlertCardWarningPreview() {
    TeslaTheme {
        TeslaAlertCard(
            message = "ネットワーク接続が不安定です",
            variant = TeslaAlertVariant.Warning,
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaAlertCardErrorPreview() {
    TeslaTheme {
        TeslaAlertCard(
            message = "API接続に失敗しました",
            variant = TeslaAlertVariant.Error,
            modifier = Modifier.padding(16.dp)
        )
    }
}
