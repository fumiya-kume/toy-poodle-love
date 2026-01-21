package com.fumiyakume.viewer.ui.settings

import app.cash.turbine.test
import com.fumiyakume.viewer.data.local.AppSettings
import com.fumiyakume.viewer.data.local.SettingsDataStore
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SettingsViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var settingsDataStore: SettingsDataStore
    private lateinit var viewModel: SettingsViewModel

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        settingsDataStore = mockk(relaxed = true)

        // デフォルト値を返すFlowを設定
        every { settingsDataStore.controlHideDelayMs } returns flowOf(3000L)
        every { settingsDataStore.defaultOverlayOpacity } returns flowOf(0.5f)
        every { settingsDataStore.defaultAIModel } returns flowOf("gemini")

        viewModel = SettingsViewModel(settingsDataStore)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ========== 初期状態テスト ==========

    @Test
    fun `settings emits initial values from datastore`() = runTest {
        viewModel.settings.test {
            val initial = awaitItem()
            assertEquals(3000L, initial.controlHideDelayMs)
            assertEquals(0.5f, initial.defaultOverlayOpacity)
            assertEquals("gemini", initial.defaultAIModel)
        }
    }

    @Test
    fun `settings has correct default values`() = runTest {
        // デフォルトのAppSettingsの値を検証
        val defaultSettings = AppSettings()
        assertEquals(3000L, defaultSettings.controlHideDelayMs)
        assertEquals(0.5f, defaultSettings.defaultOverlayOpacity)
        assertEquals("gemini", defaultSettings.defaultAIModel)
    }

    // ========== 設定更新テスト ==========

    @Test
    fun `updateControlHideDelay calls datastore with correct value`() = runTest {
        coEvery { settingsDataStore.setControlHideDelayMs(any()) } returns Unit

        viewModel.updateControlHideDelay(5000L)
        advanceUntilIdle()

        coVerify { settingsDataStore.setControlHideDelayMs(5000L) }
    }

    @Test
    fun `updateDefaultOverlayOpacity calls datastore with correct value`() = runTest {
        coEvery { settingsDataStore.setDefaultOverlayOpacity(any()) } returns Unit

        viewModel.updateDefaultOverlayOpacity(0.75f)
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultOverlayOpacity(0.75f) }
    }

    @Test
    fun `updateDefaultAIModel calls datastore with correct value`() = runTest {
        coEvery { settingsDataStore.setDefaultAIModel(any()) } returns Unit

        viewModel.updateDefaultAIModel("qwen")
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultAIModel("qwen") }
    }

    // ========== 境界値テスト ==========

    @Test
    fun `updateControlHideDelay accepts minimum value`() = runTest {
        coEvery { settingsDataStore.setControlHideDelayMs(any()) } returns Unit

        viewModel.updateControlHideDelay(1000L)
        advanceUntilIdle()

        coVerify { settingsDataStore.setControlHideDelayMs(1000L) }
    }

    @Test
    fun `updateControlHideDelay accepts maximum value`() = runTest {
        coEvery { settingsDataStore.setControlHideDelayMs(any()) } returns Unit

        viewModel.updateControlHideDelay(10000L)
        advanceUntilIdle()

        coVerify { settingsDataStore.setControlHideDelayMs(10000L) }
    }

    @Test
    fun `updateDefaultOverlayOpacity accepts minimum value`() = runTest {
        coEvery { settingsDataStore.setDefaultOverlayOpacity(any()) } returns Unit

        viewModel.updateDefaultOverlayOpacity(0f)
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultOverlayOpacity(0f) }
    }

    @Test
    fun `updateDefaultOverlayOpacity accepts maximum value`() = runTest {
        coEvery { settingsDataStore.setDefaultOverlayOpacity(any()) } returns Unit

        viewModel.updateDefaultOverlayOpacity(1f)
        advanceUntilIdle()

        coVerify { settingsDataStore.setDefaultOverlayOpacity(1f) }
    }
}
