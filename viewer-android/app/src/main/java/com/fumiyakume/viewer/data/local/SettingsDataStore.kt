package com.fumiyakume.viewer.data.local

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * アプリ設定を永続化するDataStore
 *
 * Preferences DataStoreを使用してキーバリュー形式で保存
 */
@Singleton
class SettingsDataStore @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    private object PreferencesKeys {
        val CONTROL_HIDE_DELAY_MS = longPreferencesKey("control_hide_delay_ms")
        val DEFAULT_OVERLAY_OPACITY = floatPreferencesKey("default_overlay_opacity")
        val DEFAULT_AI_MODEL = stringPreferencesKey("default_ai_model")
    }

    // デフォルト値
    companion object {
        const val DEFAULT_CONTROL_HIDE_DELAY_MS = 3000L
        const val DEFAULT_OVERLAY_OPACITY_VALUE = 0.5f
        const val DEFAULT_AI_MODEL_VALUE = "gemini"
    }

    /**
     * コントロール非表示の遅延時間 (ミリ秒)
     */
    val controlHideDelayMs: Flow<Long> = dataStore.data
        .map { preferences ->
            preferences[PreferencesKeys.CONTROL_HIDE_DELAY_MS] ?: DEFAULT_CONTROL_HIDE_DELAY_MS
        }

    suspend fun setControlHideDelayMs(delayMs: Long) {
        dataStore.edit { preferences ->
            preferences[PreferencesKeys.CONTROL_HIDE_DELAY_MS] = delayMs.coerceIn(1000, 10000)
        }
    }

    /**
     * デフォルトのオーバーレイ透明度
     */
    val defaultOverlayOpacity: Flow<Float> = dataStore.data
        .map { preferences ->
            preferences[PreferencesKeys.DEFAULT_OVERLAY_OPACITY] ?: DEFAULT_OVERLAY_OPACITY_VALUE
        }

    suspend fun setDefaultOverlayOpacity(opacity: Float) {
        dataStore.edit { preferences ->
            preferences[PreferencesKeys.DEFAULT_OVERLAY_OPACITY] = opacity.coerceIn(0f, 1f)
        }
    }

    /**
     * デフォルトのAIモデル
     */
    val defaultAIModel: Flow<String> = dataStore.data
        .map { preferences ->
            preferences[PreferencesKeys.DEFAULT_AI_MODEL] ?: DEFAULT_AI_MODEL_VALUE
        }

    suspend fun setDefaultAIModel(model: String) {
        dataStore.edit { preferences ->
            preferences[PreferencesKeys.DEFAULT_AI_MODEL] = model
        }
    }
}

/**
 * アプリ設定のデータクラス
 */
data class AppSettings(
    val controlHideDelayMs: Long = SettingsDataStore.DEFAULT_CONTROL_HIDE_DELAY_MS,
    val defaultOverlayOpacity: Float = SettingsDataStore.DEFAULT_OVERLAY_OPACITY_VALUE,
    val defaultAIModel: String = SettingsDataStore.DEFAULT_AI_MODEL_VALUE
)
