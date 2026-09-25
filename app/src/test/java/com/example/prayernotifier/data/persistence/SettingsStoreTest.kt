package com.example.prayernotifier.data.persistence

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class SettingsStoreTest {

    private lateinit var store: InMemoryKeyValueStore
    private lateinit var settings: SettingsStore

    @Before
    fun setUp() {
        store = InMemoryKeyValueStore()
        settings = SettingsStore(store)
    }

    @Test
    fun `empty store loads defaults`() = runTest {
        val loaded = settings.load()
        assertEquals(AppSettings(), loaded)
        assertEquals(5, loaded.fajrSettings.prePrayerReminderMinutes)
        assertEquals(10, loaded.maghribSettings.prePrayerReminderMinutes)
        assertEquals(0, loaded.hijriDateAdjustment)
        assertEquals(0, loaded.timeAdjustments.fajrAdjustment)
    }

    @Test
    fun `save then load roundtrips`() = runTest {
        val custom = AppSettings(
            fajrSettings = PrayerNotificationSettings(enabled = false, prePrayerReminderMinutes = 15),
            hijriDateAdjustment = 1,
            timeAdjustments = PrayerTimeAdjustments(maghribAdjustment = 2)
        )
        settings.save(custom)
        assertEquals(custom, settings.load())
    }

    @Test
    fun `corrupt data loads defaults`() = runTest {
        store.put(SettingsStore.KEY, "broken{{{")
        assertEquals(AppSettings(), settings.load())
    }

    @Test
    fun `prayer lookup helpers work`() {
        val loaded = AppSettings()
        assertEquals(loaded.maghribSettings, loaded.getSettingsForPrayer("Maghrib"))
        assertEquals(10, loaded.travelTimeSettings.getTravelTimeForPrayer("Fajr"))
        assertEquals(0, loaded.timeAdjustments.getAdjustmentForPrayer("Isha"))
    }
}
