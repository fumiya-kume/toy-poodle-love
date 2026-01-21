package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Tesla UIスタイルのスライダー
 *
 * ラベル付きで値の表示が可能
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeslaSlider(
    value: Float,
    onValueChange: (Float) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    valueRange: ClosedFloatingPointRange<Float> = 0f..1f,
    steps: Int = 0,
    enabled: Boolean = true,
    showValue: Boolean = true,
    valueFormatter: (Float) -> String = { "${(it * 100).toInt()}%" }
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        if (label != null || showValue) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (label != null) {
                    Text(
                        text = label,
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextSecondary
                    )
                }

                if (showValue) {
                    Text(
                        text = valueFormatter(value),
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextPrimary
                    )
                }
            }
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(24.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(TeslaColors.GlassBackground)
                .padding(horizontal = 4.dp),
            contentAlignment = Alignment.Center
        ) {
            Slider(
                value = value,
                onValueChange = onValueChange,
                valueRange = valueRange,
                steps = steps,
                enabled = enabled,
                colors = SliderDefaults.colors(
                    thumbColor = TeslaColors.Accent,
                    activeTrackColor = TeslaColors.Accent,
                    inactiveTrackColor = TeslaColors.GlassBorder,
                    disabledThumbColor = TeslaColors.TextTertiary,
                    disabledActiveTrackColor = TeslaColors.TextTertiary,
                    disabledInactiveTrackColor = TeslaColors.GlassBorder
                ),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaSliderPreview() {
    TeslaTheme {
        var value by remember { mutableFloatStateOf(0.5f) }
        TeslaSlider(
            value = value,
            onValueChange = { value = it },
            label = "透明度",
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        )
    }
}
