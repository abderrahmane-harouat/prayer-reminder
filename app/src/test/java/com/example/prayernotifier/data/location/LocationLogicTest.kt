package com.example.prayernotifier.data.location

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LocationListOpsTest {

    @Test
    fun `same area matches on 2-decimal rounding`() {
        assertTrue(LocationListOps.sameArea(21.4225, 39.8262, 21.4249, 39.8299))
        assertFalse(LocationListOps.sameArea(21.4225, 39.8262, 24.5247, 39.5692))
    }

    @Test
    fun `upsert appends new area`() {
        val list = listOf(SavedLocation("Mecca", 21.4225, 39.8262, 1L))
        val updated = LocationListOps.upsert(list, SavedLocation("Medina", 24.5247, 39.5692, 2L))
        assertEquals(listOf("Mecca", "Medina"), updated.map { it.name })
    }

    @Test
    fun `upsert replaces same-area entry`() {
        val list = listOf(SavedLocation("Mecca", 21.4225, 39.8262, 1L))
        val updated = LocationListOps.upsert(list, SavedLocation("Makkah", 21.4249, 39.8299, 2L))
        assertEquals(1, updated.size)
        assertEquals(SavedLocation("Makkah", 21.4249, 39.8299, 2L), updated[0])
    }

    @Test
    fun `remove drops same-area entries only`() {
        val list = listOf(
            SavedLocation("Mecca", 21.4225, 39.8262, 1L),
            SavedLocation("Medina", 24.5247, 39.5692, 2L)
        )
        val updated = LocationListOps.remove(list, 21.4249, 39.8299)
        assertEquals(listOf("Medina"), updated.map { it.name })
    }
}

class PickPlaceNameTest {

    @Test
    fun `prefers locality then admin area then country then feature`() {
        assertEquals("Mecca", pickPlaceName("Mecca", "Makkah", "Saudi Arabia", "X"))
        assertEquals("Makkah", pickPlaceName(null, "Makkah", "Saudi Arabia", "X"))
        assertEquals("Makkah", pickPlaceName("  ", "Makkah", "Saudi Arabia", "X"))
        assertEquals("Saudi Arabia", pickPlaceName(null, null, "Saudi Arabia", "X"))
        assertEquals("X", pickPlaceName(null, null, null, "X"))
        assertNull(pickPlaceName(null, null, null, null))
        assertNull(pickPlaceName("", " ", null, ""))
    }
}
