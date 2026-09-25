package com.example.prayernotifier.data

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Live smoke test against the real Aladhan API.
 * Requires internet; verifies the endpoint, params and payload shape end-to-end.
 */
class AladhanLiveTest {

    private val repository = PrayerRepository(AladhanApi.create())
    private val timePattern = Regex("""\d{2}:\d{2}""")

    @Test
    fun `fetches september 2026 for mecca`() = runBlocking {
        val days = repository.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)

        assertEquals(30, days.size)
        for (day in days) {
            val t = day.timings
            for (time in listOf(t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha)) {
                assertTrue("bad time: $time", timePattern.matches(time))
            }
            assertTrue(day.readableDate.isNotBlank())
            assertTrue(day.hijri.day.isNotBlank())
            assertTrue(day.hijri.monthEn.isNotBlank())
            assertTrue(day.hijri.year.isNotBlank())
        }
        println("Sample day 1: ${days[0]}")
    }
}
