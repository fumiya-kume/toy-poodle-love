package com.fumiyakume.viewer.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.fumiyakume.viewer.R
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * ホーム画面
 *
 * カードグリッドでビデオプレイヤーとシナリオライターへのナビゲーションを提供
 */
@Composable
fun HomeScreen(
    onNavigateToVideoPlayer: () -> Unit = {},
    onNavigateToScenarioWriter: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {}
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(TeslaTheme.colors.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Viewer",
                    style = TeslaTheme.typography.displayMedium,
                    color = TeslaTheme.colors.textPrimary
                )

                IconButton(onClick = onNavigateToSettings) {
                    Icon(
                        imageVector = Icons.Default.Settings,
                        contentDescription = stringResource(R.string.settings_title),
                        tint = TeslaTheme.colors.textSecondary
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Card Grid
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(0.dp),
                horizontalArrangement = Arrangement.spacedBy(24.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                item {
                    HomeCard(
                        icon = Icons.Default.PlayArrow,
                        title = stringResource(R.string.home_video_player_title),
                        description = stringResource(R.string.home_video_player_description),
                        accentColor = TeslaTheme.colors.accent,
                        onClick = onNavigateToVideoPlayer
                    )
                }

                item {
                    HomeCard(
                        icon = Icons.Default.Edit,
                        title = stringResource(R.string.home_scenario_writer_title),
                        description = stringResource(R.string.home_scenario_writer_description),
                        accentColor = TeslaTheme.colors.statusOrange,
                        onClick = onNavigateToScenarioWriter
                    )
                }
            }
        }
    }
}

@Composable
private fun HomeCard(
    icon: ImageVector,
    title: String,
    description: String,
    accentColor: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = TeslaTheme.colors.surface
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Icon with accent background
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(accentColor.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = accentColor,
                    modifier = Modifier.size(32.dp)
                )
            }

            Column {
                Text(
                    text = title,
                    style = TeslaTheme.typography.headlineMedium,
                    color = TeslaTheme.colors.textPrimary
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = description,
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaTheme.colors.textSecondary
                )
            }
        }
    }
}

@Preview(
    showBackground = true,
    widthDp = 1024,
    heightDp = 768
)
@Composable
private fun HomeScreenPreview() {
    TeslaTheme {
        HomeScreen()
    }
}
