package com.fumiyakume.viewer.data.local

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import com.fumiyakume.viewer.test.MainDispatcherRule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

@OptIn(ExperimentalCoroutinesApi::class)
class SettingsDataStoreTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @get:Rule
    val temporaryFolder = TemporaryFolder()

    private lateinit var scope: CoroutineScope
    private lateinit var dataStore: DataStore<Preferences>
    private lateinit var settingsDataStore: SettingsDataStore

    @Before
    fun setUp() {
        scope = CoroutineScope(SupervisorJob() + mainDispatcherRule.dispatcher)
        val file = temporaryFolder.newFile("viewer_settings.preferences_pb")
        dataStore = PreferenceDataStoreFactory.create(scope = scope) { file }
        settingsDataStore = SettingsDataStore(dataStore)
    }

    @After
    fun tearDown() {
        scope.cancel()
    }

    @Test
    fun defaults_areEmitted_whenNoPreferencesWritten() = runTest(mainDispatcherRule.dispatcher) {
        assertEquals(SettingsDataStore.DEFAULT_CONTROL_HIDE_DELAY_MS, settingsDataStore.controlHideDelayMs.first())
        assertEquals(SettingsDataStore.DEFAULT_OVERLAY_OPACITY_VALUE, settingsDataStore.defaultOverlayOpacity.first())
        assertEquals(SettingsDataStore.DEFAULT_AI_MODEL_VALUE, settingsDataStore.defaultAIModel.first())
    }

    @Test
    fun setControlHideDelayMs_clampsToValidRange() = runTest(mainDispatcherRule.dispatcher) {
        settingsDataStore.setControlHideDelayMs(0L)
        advanceUntilIdle()
        assertEquals(1000L, settingsDataStore.controlHideDelayMs.first())

        settingsDataStore.setControlHideDelayMs(20_000L)
        advanceUntilIdle()
        assertEquals(10_000L, settingsDataStore.controlHideDelayMs.first())
    }

    @Test
    fun setDefaultOverlayOpacity_clampsToValidRange() = runTest(mainDispatcherRule.dispatcher) {
        settingsDataStore.setDefaultOverlayOpacity(-1f)
        advanceUntilIdle()
        assertEquals(0f, settingsDataStore.defaultOverlayOpacity.first())

        settingsDataStore.setDefaultOverlayOpacity(2f)
        advanceUntilIdle()
        assertEquals(1f, settingsDataStore.defaultOverlayOpacity.first())
    }

    @Test
    fun setDefaultAIModel_persistsValue() = runTest(mainDispatcherRule.dispatcher) {
        settingsDataStore.setDefaultAIModel("qwen")
        advanceUntilIdle()
        assertEquals("qwen", settingsDataStore.defaultAIModel.first())
    }
}

