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
    val colors = alertColors(variant)
    val defaultIcon = alertDefaultIcon(variant)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(colors.backgroundColor)
            .border(
                width = 1.dp,
                color = colors.borderColor,
                shape = RoundedCornerShape(12.dp)
            )
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon ?: defaultIcon,
            contentDescription = null,
            tint = colors.iconTint,
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

internal data class AlertColors(
    val backgroundColor: Color,
    val borderColor: Color,
    val iconTint: Color
)

internal fun alertColors(variant: TeslaAlertVariant): AlertColors = when (variant) {
    TeslaAlertVariant.Info -> AlertColors(
        backgroundColor = TeslaColors.Accent.copy(alpha = 0.1f),
        borderColor = TeslaColors.Accent.copy(alpha = 0.3f),
        iconTint = TeslaColors.Accent
    )
    TeslaAlertVariant.Success -> AlertColors(
        backgroundColor = TeslaColors.StatusGreen.copy(alpha = 0.1f),
        borderColor = TeslaColors.StatusGreen.copy(alpha = 0.3f),
        iconTint = TeslaColors.StatusGreen
    )
    TeslaAlertVariant.Warning -> AlertColors(
        backgroundColor = TeslaColors.StatusOrange.copy(alpha = 0.1f),
        borderColor = TeslaColors.StatusOrange.copy(alpha = 0.3f),
        iconTint = TeslaColors.StatusOrange
    )
    TeslaAlertVariant.Error -> AlertColors(
        backgroundColor = TeslaColors.StatusRed.copy(alpha = 0.1f),
        borderColor = TeslaColors.StatusRed.copy(alpha = 0.3f),
        iconTint = TeslaColors.StatusRed
    )
}

internal fun alertDefaultIcon(variant: TeslaAlertVariant): ImageVector = when (variant) {
    TeslaAlertVariant.Info -> Icons.Default.Info
    TeslaAlertVariant.Success -> Icons.Default.CheckCircle
    TeslaAlertVariant.Warning -> Icons.Default.Warning
    TeslaAlertVariant.Error -> Icons.Default.Warning
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
