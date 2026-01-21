package com.fumiyakume.viewer.ui.settings

import app.cash.turbine.test
import com.fumiyakume.viewer.data.local.AppSettings
import com.fumiyakume.viewer.data.local.SettingsDataStore
import com.fumiyakume.viewer.test.MainDispatcherRule
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SettingsViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var settingsDataStore: SettingsDataStore
    private lateinit var viewModel: SettingsViewModel

    @Before
    fun setup() {
        settingsDataStore = mockk(relaxed = true)

        // デフォルト値を返すFlowを設定
        every { settingsDataStore.controlHideDelayMs } returns flowOf(3000L)
        every { settingsDataStore.defaultOverlayOpacity } returns flowOf(0.5f)
        every { settingsDataStore.defaultAIModel } returns flowOf("gemini")

        viewModel = SettingsViewModel(settingsDataStore)
    }

    // ========== 初期状態テスト ==========

    @Test
    fun `settings emits initial values from datastore`() = runTest(mainDispatcherRule.dispatcher) {
        viewModel.settings.test {
            val initial = awaitItem()
            assertEquals(3000L, initial.controlHideDelayMs)
            assertEquals(0.5f, initial.defaultOverlayOpacity)
            assertEquals("gemini", initial.defaultAIModel)
        }
    }

    @Test
    fun `settings has correct default values`() = runTest(mainDispatcherRule.dispatcher) {
        // デフォルトのAppSettingsの値を検証
        val defaultSettings = AppSettings()
        assertEquals(3000L, defaultSettings.controlHideDelayMs)
        assertEquals(0.5f, defaultSettings.defaultOverlayOpacity)
        assertEquals("gemini", defaultSettings.defaultAIModel)
    }

    // ========== 設定更新テスト ==========

    @Test
    fun `updateControlHideDelay calls datastore with correct value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setControlHideDelayMs(any()) } returns Unit

        viewModel.updateControlHideDelay(5000L)
        advanceUntilIdle()

        coVerify { settingsDataStore.setControlHideDelayMs(5000L) }
    }

    @Test
    fun `updateDefaultOverlayOpacity calls datastore with correct value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setDefaultOverlayOpacity(any()) } returns Unit

        viewModel.updateDefaultOverlayOpacity(0.75f)
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultOverlayOpacity(0.75f) }
    }

    @Test
    fun `updateDefaultAIModel calls datastore with correct value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setDefaultAIModel(any()) } returns Unit

        viewModel.updateDefaultAIModel("qwen")
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultAIModel("qwen") }
    }

    // ========== 境界値テスト ==========

    @Test
    fun `updateControlHideDelay accepts minimum value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setControlHideDelayMs(any()) } returns Unit

        viewModel.updateControlHideDelay(1000L)
        advanceUntilIdle()

        coVerify { settingsDataStore.setControlHideDelayMs(1000L) }
    }

    @Test
    fun `updateControlHideDelay accepts maximum value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setControlHideDelayMs(any()) } returns Unit

        viewModel.updateControlHideDelay(10000L)
        advanceUntilIdle()

        coVerify { settingsDataStore.setControlHideDelayMs(10000L) }
    }

    @Test
    fun `updateDefaultOverlayOpacity accepts minimum value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setDefaultOverlayOpacity(any()) } returns Unit

        viewModel.updateDefaultOverlayOpacity(0f)
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultOverlayOpacity(0f) }
    }

    @Test
    fun `updateDefaultOverlayOpacity accepts maximum value`() = runTest(mainDispatcherRule.dispatcher) {
        coEvery { settingsDataStore.setDefaultOverlayOpacity(any()) } returns Unit

        viewModel.updateDefaultOverlayOpacity(1f)
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultOverlayOpacity(1f) }
    }

    @Test
    fun `settings emits updated values when datastore flows change`() = runTest(mainDispatcherRule.dispatcher) {
        val controlHideDelayMsFlow = MutableStateFlow(5000L)
        val overlayOpacityFlow = MutableStateFlow(0.75f)
        val aiModelFlow = MutableStateFlow("qwen")

        val dataStore = mockk<SettingsDataStore>(relaxed = true)
        every { dataStore.controlHideDelayMs } returns controlHideDelayMsFlow
        every { dataStore.defaultOverlayOpacity } returns overlayOpacityFlow
        every { dataStore.defaultAIModel } returns aiModelFlow

        val viewModel = SettingsViewModel(dataStore)

        viewModel.settings.test {
            assertEquals(AppSettings(), awaitItem())
            assertEquals(
                AppSettings(
                    controlHideDelayMs = 5000L,
                    defaultOverlayOpacity = 0.75f,
                    defaultAIModel = "qwen"
                ),
                awaitItem()
            )

            controlHideDelayMsFlow.value = 8000L
            assertEquals(
                AppSettings(
                    controlHideDelayMs = 8000L,
                    defaultOverlayOpacity = 0.75f,
                    defaultAIModel = "qwen"
                ),
                awaitItem()
            )

            overlayOpacityFlow.value = 0.25f
            assertEquals(
                AppSettings(
                    controlHideDelayMs = 8000L,
                    defaultOverlayOpacity = 0.25f,
                    defaultAIModel = "qwen"
                ),
                awaitItem()
            )

            aiModelFlow.value = "gemini"
            assertEquals(
                AppSettings(
                    controlHideDelayMs = 8000L,
                    defaultOverlayOpacity = 0.25f,
                    defaultAIModel = "gemini"
                ),
                awaitItem()
            )
        }
    }
}
