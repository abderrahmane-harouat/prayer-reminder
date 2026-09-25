package com.example.prayernotifier.data

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.prayernotifier.data.connectivity.ConnectivityMonitor
import com.example.prayernotifier.data.connectivity.NetworkKind
import com.example.prayernotifier.data.persistence.PrayerDatabase
import com.example.prayernotifier.data.persistence.RoomPrayerTimesCache
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.test.runTest
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PrayerTimesRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var db: PrayerDatabase
    private lateinit var monitor: FakeConnectivityMonitor
    private lateinit var brain: PrayerTimesRepository

    @Before
    fun setUp() {
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse =
                MockResponse().setBody(MONTH_JSON).setResponseCode(200)
        }
        server.start()
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            PrayerDatabase::class.java
        ).allowMainThreadQueries().build()
        monitor = FakeConnectivityMonitor(online = true)
        brain = PrayerTimesRepository(
            network = PrayerRepository(AladhanApi.create(server.url("/").toString())),
            cache = RoomPrayerTimesCache(db.prayerDayDao(), currentYear = { 2026 }),
            connectivity = monitor,
            currentYear = { 2026 }
        )
    }

    @After
    fun tearDown() {
        server.shutdown()
        db.close()
    }

    @Test
    fun `saved month returns without touching network`() = runTest {
        brain.downloadOfflineData(21.4225, 39.8262) { _, _ -> }
        val requestsAfterBulk = server.requestCount

        val days = brain.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)

        assertEquals(2, days.size)
        assertEquals("05:12", days[0].timings.fajr)
        assertEquals(requestsAfterBulk, server.requestCount)
    }

    @Test
    fun `missing month downloads then saves`() = runTest {
        val days = brain.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)
        assertEquals(2, days.size)
        assertEquals(1, server.requestCount)

        // Second call comes from the database.
        brain.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)
        assertEquals(1, server.requestCount)
    }

    @Test
    fun `missing month offline throws`() = runTest {
        monitor.online = false
        try {
            brain.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)
            fail("expected OfflineNoCache")
        } catch (e: PrayerDataException.OfflineNoCache) {
            // Expected.
        }
        assertEquals(0, server.requestCount)
    }

    @Test
    fun `bulk download fills 120 months with progress and skips saved`() = runTest {
        // Pre-save 2 months; the bulk run must skip them.
        brain.getPrayerTimesForMonth(2025, 1, 21.4225, 39.8262)
        brain.getPrayerTimesForMonth(2025, 2, 21.4225, 39.8262)
        assertEquals(2, server.requestCount)

        val progress = mutableListOf<Pair<Int, Int>>()
        brain.downloadOfflineData(21.4225, 39.8262) { done, total -> progress.add(done to total) }

        assertEquals(120, progress.size)
        assertEquals(120 to 120, progress.last())
        assertEquals(118, server.requestCount - 2)

        val status = RoomPrayerTimesCache(db.prayerDayDao(), currentYear = { 2026 })
            .cacheStatus(21.4225, 39.8262)
        assertEquals(120, status.cachedMonths)
        assertTrue(status.isCached)
    }

    @Test
    fun `bulk download offline with full cache just reports done`() = runTest {
        brain.downloadOfflineData(21.4225, 39.8262) { _, _ -> }
        val requests = server.requestCount
        monitor.online = false

        val progress = mutableListOf<Pair<Int, Int>>()
        brain.downloadOfflineData(21.4225, 39.8262) { done, total -> progress.add(done to total) }

        assertEquals(listOf(120 to 120), progress)
        assertEquals(requests, server.requestCount)
    }

    @Test
    fun `bulk download offline with empty cache throws`() = runTest {
        monitor.online = false
        try {
            brain.downloadOfflineData(21.4225, 39.8262) { _, _ -> }
            fail("expected OfflineNoCache")
        } catch (e: PrayerDataException.OfflineNoCache) {
            // Expected.
        }
        assertEquals(0, server.requestCount)
    }

    private class FakeConnectivityMonitor(var online: Boolean) : ConnectivityMonitor {
        private val flow = MutableStateFlow(online)
        override val isOnline: StateFlow<Boolean> = flow.asStateFlow()
        override val kind: StateFlow<NetworkKind> =
            MutableStateFlow(if (online) NetworkKind.Wifi else NetworkKind.None)
        override fun refresh(): Boolean {
            flow.value = online
            return online
        }
    }

    companion object {
        private const val MONTH_JSON = """
        {
          "code": 200, "status": "OK",
          "data": [
            {
              "timings": {
                "Fajr": "05:12 (+03)", "Sunrise": "06:40 (+03)",
                "Dhuhr": "12:45 (+03)", "Asr": "16:10 (+03)",
                "Maghrib": "18:52 (+03)", "Isha": "20:20 (+03)",
                "Imsak": "05:02 (+03)", "Midnight": "00:45 (+03)"
              },
              "date": {
                "readable": "01 Sep 2026",
                "hijri": {
                  "date": "09-03-1448", "day": "09", "year": "1448",
                  "month": {"en": "Rabi al-awwal"}
                }
              }
            },
            {
              "timings": {
                "Fajr": "05:13 (+03)", "Sunrise": "06:41 (+03)",
                "Dhuhr": "12:45 (+03)", "Asr": "16:09 (+03)",
                "Maghrib": "18:51 (+03)", "Isha": "20:19 (+03)",
                "Imsak": "05:03 (+03)", "Midnight": "00:45 (+03)"
              },
              "date": {
                "readable": "02 Sep 2026",
                "hijri": {
                  "date": "10-03-1448", "day": "10", "year": "1448",
                  "month": {"en": "Rabi al-awwal"}
                }
              }
            }
          ]
        }
        """
    }
}
