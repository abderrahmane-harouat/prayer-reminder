package com.example.prayernotifier.data.notifications

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.prayernotifier.data.PrayerTimings
import com.example.prayernotifier.data.location.GeocodeProvider
import com.example.prayernotifier.data.location.InMemoryLocationStorage
import com.example.prayernotifier.data.location.LocationService
import com.example.prayernotifier.data.location.PositionOutcome
import com.example.prayernotifier.data.location.PositionProvider
import com.example.prayernotifier.data.location.SavedLocation
import com.example.prayernotifier.data.persistence.AppSettings
import com.example.prayernotifier.data.persistence.InMemoryKeyValueStore
import com.example.prayernotifier.data.persistence.PrayerDatabase
import com.example.prayernotifier.data.persistence.RoomPrayerTimesCache
import com.example.prayernotifier.data.persistence.SettingsStore
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale
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
class PrayerAlarmHandlerTest {

    private lateinit var db: PrayerDatabase
    private lateinit var storage: InMemoryLocationStorage
    private lateinit var settingsStore: SettingsStore
    private lateinit var scheduler: FakeScheduler
    private lateinit var notifier: FakeNotifier
    private lateinit var handler: PrayerAlarmHandler

    private val zone = ZoneId.systemDefault()
    private val today = LocalDate.now(zone)
    private val readable = DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH)

    @Before
    fun setUp() {
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            PrayerDatabase::class.java
        ).allowMainThreadQueries().build()
        storage = InMemoryLocationStorage()
        settingsStore = SettingsStore(InMemoryKeyValueStore())
        scheduler = FakeScheduler()
        notifier = FakeNotifier()
        val location = LocationService(FakePositions(), FakeGeocode(), storage)
        handler = PrayerAlarmHandler(
            location,
            RoomPrayerTimesCache(db.prayerDayDao()),
            settingsStore,
            scheduler,
            notifier,
            now = { today.atTime(10, 0).atZone(zone) }
        )
    }

    @After
    fun tearDown() {
        db.close()
    }

    private suspend fun seedToday() {
        storage.saveLocation(SavedLocation("Mecca", 21.4225, 39.8262, 1L))
        storage.saveCurrentLocation(
            com.example.prayernotifier.data.location.CurrentLocation("Mecca", 21.4225, 39.8262)
        )
        val cache = RoomPrayerTimesCache(db.prayerDayDao())
        val days = listOf(-1, 0, 1).map { offset ->
            val date = today.plusDays(offset.toLong())
            com.example.prayernotifier.data.PrayerDay(
                timings = PrayerTimings("05:12", "12:45", "16:10", "18:52", "20:20"),
                hijri = com.example.prayernotifier.data.HijriDate("d", "1", "M", "1448"),
                readableDate = date.format(readable)
            )
        }
        cache.save(days, today.year, today.monthValue, 21.4225, 39.8262)
    }

    @Test fun `day change re-plans today from the database`() = runTest {
        seedToday()

        assertTrue(handler.onDayChanged())

        assertEquals(1, scheduler.calls.size)
        val call = scheduler.calls[0]
        assertEquals(today, call.first)
        assertEquals("05:12", call.second.fajr)
        assertEquals("18:52", call.second.maghrib)
    }

    @Test fun `day change with empty database plans nothing`() = runTest {
        storage.saveCurrentLocation(
            com.example.prayernotifier.data.location.CurrentLocation("Mecca", 21.4225, 39.8262)
        )

        assertFalse(handler.onDayChanged())
        assertTrue(scheduler.calls.isEmpty())
    }

    @Test fun `day change without saved place plans nothing`() = runTest {
        assertFalse(handler.onDayChanged())
        assertTrue(scheduler.calls.isEmpty())
    }

    @Test fun `reminder before the prayer says how many minutes are left`() = runTest {
        handler.onAlarmFired("Maghrib", "18:52", leadMinutes = 5)

        val post = notifier.posts.single()
        assertEquals("Prayer reminder", post.second)
        assertEquals("5 minutes until Maghrib · 18:52", post.third)
    }

    @Test fun `one minute is singular`() = runTest {
        handler.onAlarmFired("Fajr", "05:12", leadMinutes = 1)
        assertEquals("1 minute until Fajr · 05:12", notifier.posts.single().third)
    }

    @Test fun `fired alarm shows the right notification`() = runTest {
        handler.onAlarmFired("Maghrib", "18:52")

        assertEquals(1, notifier.posts.size)
        val post = notifier.posts[0]
        assertEquals(4, post.first)
        assertEquals("Prayer time", post.second)
        assertTrue(post.third.contains("Maghrib"))
        assertTrue(post.third.contains("18:52"))
    }

    private class FakePositions : PositionProvider {
        override suspend fun currentFix(): PositionOutcome =
            PositionOutcome.Fix(com.example.prayernotifier.data.location.LatLng(21.4225, 39.8262))
    }

    private class FakeGeocode : GeocodeProvider {
        override suspend fun placeName(latitude: Double, longitude: Double): String? = "Mecca"
    }

    private class FakeScheduler : NotificationScheduler {
        val calls = mutableListOf<Triple<LocalDate, PrayerTimings, AppSettings>>()

        override fun scheduleDay(
            date: LocalDate,
            timings: PrayerTimings,
            settings: AppSettings,
            now: ZonedDateTime
        ): ScheduleReport {
            calls += Triple(date, timings, settings)
            return ScheduleReport(5, 0, false)
        }

        override fun cancelAll() = Unit
    }

    private class FakeNotifier : Notifier {
        val posts = mutableListOf<Triple<Int, String, String>>()

        override fun showPrayerNotification(id: Int, title: String, body: String) {
            posts += Triple(id, title, body)
        }
    }
}
