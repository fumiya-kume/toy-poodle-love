package com.fumiyakume.viewer.ui.components.molecules

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TeslaStepperTest {

    @Test
    fun calculateStepperButtonState_enablesButtonsWithinRange() {
        val state = calculateStepperButtonState(value = 5, range = 3..8, enabled = true)

        assertTrue(state.canDecrement)
        assertTrue(state.canIncrement)
    }

    @Test
    fun calculateStepperButtonState_disablesDecrementAtMin() {
        val state = calculateStepperButtonState(value = 3, range = 3..8, enabled = true)

        assertFalse(state.canDecrement)
        assertTrue(state.canIncrement)
    }

    @Test
    fun calculateStepperButtonState_disablesIncrementAtMax() {
        val state = calculateStepperButtonState(value = 8, range = 3..8, enabled = true)

        assertTrue(state.canDecrement)
        assertFalse(state.canIncrement)
    }

    @Test
    fun calculateStepperButtonState_disablesBothWhenNotEnabled() {
        val state = calculateStepperButtonState(value = 5, range = 3..8, enabled = false)

        assertFalse(state.canDecrement)
        assertFalse(state.canIncrement)
    }
}
