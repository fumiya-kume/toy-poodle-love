package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Teslaスタイルのテキストフィールド
 *
 * ラベル付きの単一行テキスト入力
 */
@Composable
fun TeslaTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    enabled: Boolean = true,
    singleLine: Boolean = true,
    isError: Boolean = false,
    errorMessage: String? = null
) {
    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(label) },
            placeholder = if (placeholder.isNotBlank()) {
                { Text(placeholder, color = TeslaColors.TextTertiary) }
            } else null,
            enabled = enabled,
            singleLine = singleLine,
            isError = isError,
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = TeslaColors.Accent,
                unfocusedBorderColor = TeslaColors.GlassBorder,
                disabledBorderColor = TeslaColors.GlassBorder.copy(alpha = 0.5f),
                errorBorderColor = TeslaColors.StatusRed,
                focusedTextColor = TeslaColors.TextPrimary,
                unfocusedTextColor = TeslaColors.TextPrimary,
                disabledTextColor = TeslaColors.TextSecondary,
                focusedLabelColor = TeslaColors.Accent,
                unfocusedLabelColor = TeslaColors.TextSecondary,
                disabledLabelColor = TeslaColors.TextTertiary,
                focusedContainerColor = TeslaColors.GlassBackground,
                unfocusedContainerColor = TeslaColors.GlassBackground,
                disabledContainerColor = TeslaColors.GlassBackground.copy(alpha = 0.5f),
                cursorColor = TeslaColors.Accent
            ),
            modifier = Modifier.fillMaxWidth()
        )

        if (isError && errorMessage != null) {
            Text(
                text = errorMessage,
                style = TeslaTheme.typography.labelSmall,
                color = TeslaColors.StatusRed,
                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaTextFieldPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            TeslaTextField(
                label = "出発地",
                value = "東京駅",
                onValueChange = {},
                placeholder = "例: 東京駅"
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaTextFieldEmptyPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            TeslaTextField(
                label = "目的・テーマ",
                value = "",
                onValueChange = {},
                placeholder = "例: 皇居周辺の観光スポット"
            )
        }
    }
}
