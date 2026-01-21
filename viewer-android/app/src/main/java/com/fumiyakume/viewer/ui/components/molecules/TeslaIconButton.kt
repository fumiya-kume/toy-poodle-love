package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Tesla UIスタイルのアイコンボタン
 *
 * ガラスモーフィズム効果のある丸角ボタン
 */
@Composable
fun TeslaIconButton(
    icon: ImageVector,
    contentDescription: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    size: TeslaIconButtonSize = TeslaIconButtonSize.Medium,
    variant: TeslaIconButtonVariant = TeslaIconButtonVariant.Glass
) {
    val backgroundColor = when (variant) {
        TeslaIconButtonVariant.Glass -> TeslaColors.GlassBackground
        TeslaIconButtonVariant.Primary -> TeslaColors.Accent.copy(alpha = 0.2f)
        TeslaIconButtonVariant.Surface -> TeslaColors.Surface
    }

    val iconTint = when {
        !enabled -> TeslaColors.TextTertiary
        variant == TeslaIconButtonVariant.Primary -> TeslaColors.Accent
        else -> TeslaColors.TextSecondary
    }

    val buttonSize = when (size) {
        TeslaIconButtonSize.Small -> 32.dp
        TeslaIconButtonSize.Medium -> 44.dp
        TeslaIconButtonSize.Large -> 56.dp
    }

    val iconSize = when (size) {
        TeslaIconButtonSize.Small -> 16.dp
        TeslaIconButtonSize.Medium -> 24.dp
        TeslaIconButtonSize.Large -> 32.dp
    }

    Box(
        modifier = modifier
            .size(buttonSize)
            .clip(RoundedCornerShape(12.dp))
            .background(backgroundColor)
            .clickable(
                enabled = enabled,
                role = Role.Button,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = iconTint,
            modifier = Modifier.size(iconSize)
        )
    }
}

/**
 * TeslaIconButtonのサイズバリアント
 */
enum class TeslaIconButtonSize {
    Small,
    Medium,
    Large
}

/**
 * TeslaIconButtonのスタイルバリアント
 */
enum class TeslaIconButtonVariant {
    Glass,
    Primary,
    Surface
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaIconButtonPreview() {
    TeslaTheme {
        TeslaIconButton(
            icon = Icons.Default.PlayArrow,
            contentDescription = "Play",
            onClick = {}
        )
    }
}
