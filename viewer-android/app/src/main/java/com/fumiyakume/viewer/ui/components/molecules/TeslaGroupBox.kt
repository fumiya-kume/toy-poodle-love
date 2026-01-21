package com.fumiyakume.viewer.ui.components.molecules

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * Tesla UIスタイルのグループボックス
 *
 * ガラスモーフィズム効果のあるコンテナ
 */
@Composable
fun TeslaGroupBox(
    modifier: Modifier = Modifier,
    title: String? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(TeslaColors.GlassBackground)
            .border(
                width = 1.dp,
                color = TeslaColors.GlassBorder,
                shape = RoundedCornerShape(16.dp)
            )
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (title != null) {
            Text(
                text = title,
                style = TeslaTheme.typography.titleMedium,
                color = TeslaColors.TextPrimary
            )
        }
        content()
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416)
@Composable
private fun TeslaGroupBoxPreview() {
    TeslaTheme {
        TeslaGroupBox(
            title = "再生設定",
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "コンテンツがここに入ります",
                style = TeslaTheme.typography.bodyMedium,
                color = TeslaColors.TextSecondary
            )
        }
    }
}
