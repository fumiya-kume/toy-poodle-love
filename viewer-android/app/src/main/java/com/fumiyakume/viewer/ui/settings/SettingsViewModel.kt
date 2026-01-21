package com.fumiyakume.viewer.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.fumiyakume.viewer.data.local.AppSettings
import com.fumiyakume.viewer.data.local.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 設定画面のViewModel
 *
 * DataStoreと連携してアプリ設定を管理
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    /**
     * 現在の設定値を監視
     */
    val settings: StateFlow<AppSettings> = combine(
        settingsDataStore.controlHideDelayMs,
        settingsDataStore.defaultOverlayOpacity,
        settingsDataStore.defaultAIModel
    ) { controlHideDelayMs, defaultOverlayOpacity, defaultAIModel ->
        AppSettings(
            controlHideDelayMs = controlHideDelayMs,
            defaultOverlayOpacity = defaultOverlayOpacity,
            defaultAIModel = defaultAIModel
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = AppSettings()
    )

    /**
     * コントロール非表示時間を更新
     */
    fun updateControlHideDelay(delayMs: Long) {
        viewModelScope.launch {
            settingsDataStore.setControlHideDelayMs(delayMs)
        }
    }

    /**
     * デフォルト透明度を更新
     */
    fun updateDefaultOverlayOpacity(opacity: Float) {
        viewModelScope.launch {
            settingsDataStore.setDefaultOverlayOpacity(opacity)
        }
    }

    /**
     * デフォルトAIモデルを更新
     */
    fun updateDefaultAIModel(model: String) {
        viewModelScope.launch {
            settingsDataStore.setDefaultAIModel(model)
        }
    }
}
