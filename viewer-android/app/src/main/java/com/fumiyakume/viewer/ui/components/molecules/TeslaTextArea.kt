package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Teslaスタイルのテキストエリア
 *
 * 複数行テキスト入力用
 */
@Composable
fun TeslaTextArea(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    enabled: Boolean = true,
    minHeight: Dp = 100.dp,
    maxLines: Int = Int.MAX_VALUE
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        placeholder = if (shouldShowPlaceholder(placeholder)) {
            { Text(placeholder, color = TeslaColors.TextTertiary) }
        } else null,
        enabled = enabled,
        singleLine = false,
        maxLines = maxLines,
        shape = RoundedCornerShape(12.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = TeslaColors.Accent,
            unfocusedBorderColor = TeslaColors.GlassBorder,
            disabledBorderColor = TeslaColors.GlassBorder.copy(alpha = 0.5f),
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
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = minHeight)
    )
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaTextAreaPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            TeslaTextArea(
                label = "プロンプト",
                value = "AIに質問したい内容を入力してください。\n複数行にわたって入力できます。",
                onValueChange = {},
                minHeight = 120.dp
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaTextAreaEmptyPreview() {
    TeslaTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            TeslaTextArea(
                label = "住所リスト",
                value = "",
                onValueChange = {},
                placeholder = "1行に1住所を入力\n例:\n東京駅\n新宿駅"
            )
        }
    }
}
