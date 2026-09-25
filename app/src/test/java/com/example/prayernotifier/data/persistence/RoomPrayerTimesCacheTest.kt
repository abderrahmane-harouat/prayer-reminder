package com.example.prayernotifier.data.persistence

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.prayernotifier.data.HijriDate
import com.example.prayernotifier.data.PrayerDay
import com.example.prayernotifier.data.PrayerTimings
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomPrayerTimesCacheTest {

    private lateinit var db: PrayerDatabase
    private lateinit var cache: RoomPrayerTimesCache

    @Before
    fun setUp() {
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            PrayerDatabase::class.java
        ).allowMainThreadQueries().build()
        cache = RoomPrayerTimesCache(db.prayerDayDao(), currentYear = { 2026 })
    }

    @After
    fun tearDown() {
        db.close()
    }

    private fun sampleDay(readable: String, fajr: String = "05:12") = PrayerDay(
        timings = PrayerTimings(fajr, "12:45", "16:10", "18:52", "20:20"),
        hijri = HijriDate("09-03-1448", "09", "Rabi al-awwal", "1448"),
        readableDate = readable
    )

    @Test
    fun `save then load roundtrips a month in day order`() = runTest {
        val days = listOf(sampleDay("02 Sep 2026", "05:13"), sampleDay("01 Sep 2026"))
        cache.save(days, 2026, 9, 21.4225, 39.8262)

        val loaded = cache.load(2026, 9, 21.4225, 39.8262)
        assertEquals(2, loaded.size)
        assertEquals("05:13", loaded[0].timings.fajr)
        assertEquals("02 Sep 2026", loaded[0].readableDate)
        assertEquals("05:12", loaded[1].timings.fajr)
    }

    @Test
    fun `missing month loads empty`() = runTest {
        assertTrue(cache.load(2026, 9, 21.4225, 39.8262).isEmpty())
    }

    @Test
    fun `saving twice overwrites instead of duplicating`() = runTest {
        cache.save(listOf(sampleDay("01 Sep 2026", "05:10")), 2026, 9, 21.4225, 39.8262)
        cache.save(listOf(sampleDay("01 Sep 2026", "05:12")), 2026, 9, 21.4225, 39.8262)

        val loaded = cache.load(2026, 9, 21.4225, 39.8262)
        assertEquals(1, loaded.size)
        assertEquals("05:12", loaded[0].timings.fajr)
    }

    @Test
    fun `clearAllForLocation keeps other places`() = runTest {
        cache.save(listOf(sampleDay("d1")), 2026, 9, 21.4225, 39.8262)
        cache.save(listOf(sampleDay("d2")), 2026, 10, 21.4225, 39.8262)
        cache.save(listOf(sampleDay("d3")), 2026, 9, 24.5247, 39.5692)

        cache.clearAllForLocation(21.4249, 39.8299)

        assertTrue(cache.load(2026, 9, 21.4225, 39.8262).isEmpty())
        assertTrue(cache.load(2026, 10, 21.4225, 39.8262).isEmpty())
        assertEquals(1, cache.load(2026, 9, 24.5247, 39.5692).size)
    }

    @Test
    fun `cache status counts months over the 10-year window`() = runTest {
        // Window for 2026: 2025..2034 → 120 months.
        cache.save(listOf(sampleDay("d1")), 2025, 1, 21.4225, 39.8262)
        cache.save(listOf(sampleDay("d2")), 2026, 9, 21.4225, 39.8262)

        val status = cache.cacheStatus(21.4225, 39.8262)

        assertEquals(2, status.cachedMonths)
        assertEquals(120, status.totalMonths)
        assertFalse(status.isCached)
        assertEquals("2025 - 2034", status.yearsRange)
        assertTrue(cache.hasAnyCachedData())
    }

    @Test
    fun `empty cache reports zero`() = runTest {
        val status = cache.cacheStatus(21.4225, 39.8262)
        assertEquals(0, status.cachedMonths)
        assertEquals(120, status.totalMonths)
        assertFalse(status.isCached)
        assertFalse(cache.hasAnyCachedData())
    }
}
