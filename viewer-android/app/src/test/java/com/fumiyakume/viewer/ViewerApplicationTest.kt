package com.fumiyakume.viewer

import org.junit.Assert.assertEquals
import org.junit.Test

class ViewerApplicationTest {

    @Test
    fun applicationTag_hasExpectedValue() {
        assertEquals("ViewerApplication", ViewerApplication.APPLICATION_TAG)
    }
}
