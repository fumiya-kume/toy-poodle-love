package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Teslaスタイルの数値ステッパー
 *
 * +/- ボタンで数値を増減
 */
@Composable
fun TeslaStepper(
    label: String,
    value: Int,
    onValueChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    range: IntRange = 1..10,
    enabled: Boolean = true
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = label,
            style = TeslaTheme.typography.bodyMedium,
            color = TeslaColors.TextPrimary
        )

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // マイナスボタン
            IconButton(
                onClick = {
                    if (value > range.first) {
                        onValueChange(value - 1)
                    }
                },
                enabled = enabled && value > range.first,
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(
                        if (enabled && value > range.first)
                            TeslaColors.GlassBackground
                        else
                            TeslaColors.GlassBackground.copy(alpha = 0.5f)
                    )
            ) {
                Icon(
                    imageVector = Icons.Default.Remove,
                    contentDescription = "減らす",
                    tint = if (enabled && value > range.first)
                        TeslaColors.TextPrimary
                    else
                        TeslaColors.TextTertiary
                )
            }

            // 現在値
            Text(
                text = value.toString(),
                style = TeslaTheme.typography.titleMedium,
                color = TeslaColors.TextPrimary,
                modifier = Modifier.padding(horizontal = 12.dp)
            )

            // プラスボタン
            IconButton(
                onClick = {
                    if (value < range.last) {
                        onValueChange(value + 1)
                    }
                },
                enabled = enabled && value < range.last,
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(
                        if (enabled && value < range.last)
                            TeslaColors.GlassBackground
                        else
                            TeslaColors.GlassBackground.copy(alpha = 0.5f)
                    )
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "増やす",
                    tint = if (enabled && value < range.last)
                        TeslaColors.TextPrimary
                    else
                        TeslaColors.TextTertiary
                )
            }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaStepperPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            TeslaStepper(
                label = "生成地点数",
                value = 5,
                onValueChange = {},
                range = 3..8
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaStepperMinPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            TeslaStepper(
                label = "生成地点数",
                value = 3,
                onValueChange = {},
                range = 3..8
            )
        }
    }
}
