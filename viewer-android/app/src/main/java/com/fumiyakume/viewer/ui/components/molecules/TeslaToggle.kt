package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Tesla UIスタイルのトグルスイッチ
 *
 * ラベル付きでOn/Off状態を切り替え
 */
@Composable
fun TeslaToggle(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    enabled: Boolean = true
) {
    val trackColor by animateColorAsState(
        targetValue = if (checked) TeslaColors.Accent else TeslaColors.GlassBackground,
        animationSpec = TeslaTheme.animation.quickSpec(),
        label = "trackColor"
    )

    val thumbOffset by animateDpAsState(
        targetValue = if (checked) 20.dp else 0.dp,
        animationSpec = TeslaTheme.animation.quickSpec(),
        label = "thumbOffset"
    )

    Row(
        modifier = modifier
            .toggleable(
                value = checked,
                enabled = enabled,
                role = Role.Switch,
                onValueChange = onCheckedChange
            ),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (label != null) {
            Text(
                text = label,
                style = TeslaTheme.typography.bodyMedium,
                color = if (enabled) TeslaColors.TextPrimary else TeslaColors.TextTertiary
            )
        }

        Box(
            modifier = Modifier
                .width(48.dp)
                .height(28.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(trackColor)
                .padding(4.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(20.dp)
                    .offset(x = thumbOffset)
                    .clip(CircleShape)
                    .background(
                        if (enabled) TeslaColors.TextPrimary
                        else TeslaColors.TextTertiary
                    )
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaTogglePreview() {
    TeslaTheme {
        var checked by remember { mutableStateOf(false) }
        TeslaToggle(
            checked = checked,
            onCheckedChange = { checked = it },
            label = "自動再生",
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        )
    }
}
