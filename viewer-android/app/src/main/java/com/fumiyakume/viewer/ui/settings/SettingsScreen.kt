package com.fumiyakume.viewer.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.fumiyakume.viewer.BuildConfig
import com.fumiyakume.viewer.data.local.AppSettings
import com.fumiyakume.viewer.ui.components.molecules.ModelPickerView
import com.fumiyakume.viewer.ui.components.molecules.TeslaGroupBox
import com.fumiyakume.viewer.ui.components.molecules.TeslaSlider
import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.theme.TeslaColors
import com.fumiyakume.viewer.ui.theme.TeslaTheme

/**
 * 設定画面
 *
 * アプリの各種設定を変更
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "設定",
                        color = TeslaColors.TextPrimary
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "戻る",
                            tint = TeslaColors.TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = TeslaColors.Surface
                )
            )
        },
        containerColor = TeslaColors.Background,
        modifier = modifier
    ) { paddingValues ->
        SettingsContent(
            settings = settings,
            onControlHideDelayChange = viewModel::updateControlHideDelay,
            onOverlayOpacityChange = viewModel::updateDefaultOverlayOpacity,
            onAIModelChange = viewModel::updateDefaultAIModel,
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        )
    }
}

@Composable
internal fun SettingsContent(
    settings: AppSettings,
    onControlHideDelayChange: (Long) -> Unit,
    onOverlayOpacityChange: (Float) -> Unit,
    onAIModelChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // ビデオプレイヤー設定
        TeslaGroupBox(title = "ビデオプレイヤー") {
            Column(
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // コントロール非表示時間
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "コントロール非表示時間",
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.TextPrimary
                        )
                        Text(
                            text = "${settings.controlHideDelayMs / 1000} 秒",
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.Accent
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    TeslaSlider(
                        value = (settings.controlHideDelayMs / 1000f),
                        onValueChange = { seconds ->
                            onControlHideDelayChange((seconds * 1000).toLong())
                        },
                        valueRange = 1f..10f,
                        steps = 8,
                        showValue = false
                    )

                    Text(
                        text = "操作後にコントロールが自動で非表示になるまでの時間",
                        style = TeslaTheme.typography.labelSmall,
                        color = TeslaColors.TextTertiary
                    )
                }

                // デフォルト透明度
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "デフォルトオーバーレイ透明度",
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.TextPrimary
                        )
                        Text(
                            text = "${(settings.defaultOverlayOpacity * 100).toInt()}%",
                            style = TeslaTheme.typography.bodyMedium,
                            color = TeslaColors.Accent
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    TeslaSlider(
                        value = settings.defaultOverlayOpacity,
                        onValueChange = onOverlayOpacityChange,
                        showValue = false
                    )

                    Text(
                        text = "オーバーレイビデオの初期透明度",
                        style = TeslaTheme.typography.labelSmall,
                        color = TeslaColors.TextTertiary
                    )
                }
            }
        }

        // シナリオライター設定
        TeslaGroupBox(title = "シナリオライター") {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "デフォルトAIモデル",
                    style = TeslaTheme.typography.bodyMedium,
                    color = TeslaColors.TextPrimary
                )

                ModelPickerView(
                    selectedModel = AIModel.entries.find { it.value == settings.defaultAIModel }
                        ?: AIModel.GEMINI,
                    onModelSelected = { model ->
                        onAIModelChange(model.value)
                    },
                    label = ""
                )

                Text(
                    text = "シナリオ生成で使用するデフォルトのAIモデル",
                    style = TeslaTheme.typography.labelSmall,
                    color = TeslaColors.TextTertiary
                )
            }
        }

        // アプリ情報
        TeslaGroupBox(title = "アプリ情報") {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "バージョン",
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextSecondary
                    )
                    Text(
                        text = BuildConfig.VERSION_NAME,
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextPrimary
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "ビルド",
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextSecondary
                    )
                    Text(
                        text = if (BuildConfig.DEBUG) "Debug" else "Release",
                        style = TeslaTheme.typography.bodyMedium,
                        color = TeslaColors.TextPrimary
                    )
                }
            }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF141416, widthDp = 800, heightDp = 600)
@Composable
private fun SettingsScreenPreview() {
    TeslaTheme {
        SettingsContent(
            settings = AppSettings(
                controlHideDelayMs = 3000,
                defaultOverlayOpacity = 0.5f,
                defaultAIModel = "gemini"
            ),
            onControlHideDelayChange = {},
            onOverlayOpacityChange = {},
            onAIModelChange = {},
            modifier = Modifier
                .fillMaxSize()
                .background(TeslaColors.Background)
        )
    }
}
