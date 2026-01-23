package com.fumiyakume.viewer.ui.components.organisms

import org.junit.Assert.assertEquals
import org.junit.Test

class VideoControlsOverlayTest {

    @Test
    fun calculateProgress_returnsZeroWhenDurationIsNotPositive() {
        assertEquals(0f, calculateProgress(currentPositionMs = 1000L, durationMs = 0L))
        assertEquals(0f, calculateProgress(currentPositionMs = 1000L, durationMs = -1L))
    }

    @Test
    fun calculateProgress_clampsBetweenZeroAndOne() {
        assertEquals(0f, calculateProgress(currentPositionMs = -1000L, durationMs = 10_000L))
        assertEquals(1f, calculateProgress(currentPositionMs = 20_000L, durationMs = 10_000L))
    }

    @Test
    fun calculateProgress_returnsExactRatioWithinBounds() {
        assertEquals(0.5f, calculateProgress(currentPositionMs = 5_000L, durationMs = 10_000L))
    }

    @Test
    fun formatDuration_formatsUnderOneHour() {
        assertEquals("0:00", formatDuration(0L))
        assertEquals("1:05", formatDuration(65_000L))
        assertEquals("59:59", formatDuration(3_599_000L))
    }

    @Test
    fun formatDuration_formatsHoursWhenNeeded() {
        assertEquals("1:00:00", formatDuration(3_600_000L))
        assertEquals("2:01:05", formatDuration(7_265_000L))
    }

    @Test
    fun formatDuration_handlesNegativeValues() {
        assertEquals("0:00", formatDuration(-1L))
    }
}
