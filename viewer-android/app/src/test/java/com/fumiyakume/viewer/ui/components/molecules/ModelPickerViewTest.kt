package com.fumiyakume.viewer.ui.components.molecules

import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.ScenarioModels
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ModelPickerViewTest {

    @Test
    fun buildModelPickerOptions_marksSelectedModel() {
        val options = buildModelPickerOptions(AIModel.QWEN)

        assertEquals(AIModel.entries.size, options.size)
        assertTrue(options.first { it.value == AIModel.QWEN }.isSelected)
        assertFalse(options.first { it.value == AIModel.GEMINI }.isSelected)
    }

    @Test
    fun buildScenarioModelPickerOptions_marksSelectedModels() {
        val options = buildScenarioModelPickerOptions(ScenarioModels.BOTH)

        assertEquals(ScenarioModels.entries.size, options.size)
        assertTrue(options.first { it.value == ScenarioModels.BOTH }.isSelected)
        assertFalse(options.first { it.value == ScenarioModels.GEMINI }.isSelected)
        assertFalse(options.first { it.value == ScenarioModels.QWEN }.isSelected)
    }
}
