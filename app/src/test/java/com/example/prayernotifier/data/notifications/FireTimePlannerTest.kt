package com.example.prayernotifier.data.notifications

import com.example.prayernotifier.data.PrayerTimings
import com.example.prayernotifier.data.persistence.AppSettings
import com.example.prayernotifier.data.persistence.PrayerNotificationSettings
import com.example.prayernotifier.data.persistence.PrayerTimeAdjustments
import java.time.LocalDate
import java.time.Month
import java.time.ZoneId
import java.time.ZonedDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FireTimePlannerTest {

    private val zone = ZoneId.systemDefault()
    private val date = LocalDate.of(2026, Month.SEPTEMBER, 15)
    private val timings = PrayerTimings(
        fajr = "05:12", dhuhr = "12:45", asr = "16:10",
        maghrib = "18:52", isha = "20:20"
    )

    private fun at(hour: Int, minute: Int): ZonedDateTime =
        ZonedDateTime.of(date, java.time.LocalTime.of(hour, minute), zone)

    @Test fun `plans all five with reminder subtracted`() {
        val plan = FireTimePlanner.plan(date, timings, AppSettings(), at(4, 0))

        assertEquals(0, plan.skippedPast)
        assertEquals(
            listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"),
            plan.planned.map { it.prayer }
        )
        val fires = plan.planned.associate { it.prayer to it.fireAt }
        assertEquals(at(5, 7), fires["Fajr"])
        assertEquals(at(12, 40), fires["Dhuhr"])
        assertEquals(at(16, 5), fires["Asr"])
        assertEquals(at(18, 42), fires["Maghrib"]) // Maghrib default reminds 10 min early.
        assertEquals(at(20, 15), fires["Isha"])
        assertEquals("05:12", plan.planned[0].timeString)
        assertEquals(
            AppSettings().getSettingsForPrayer("Fajr").prePrayerReminderMinutes,
            plan.planned[0].leadMinutes
        )
    }

    @Test fun `disabled prayer is excluded, not counted as skipped`() {
        val settings = AppSettings(fajrSettings = PrayerNotificationSettings(enabled = false))
        val plan = FireTimePlanner.plan(date, timings, settings, at(4, 0))
        assertEquals(4, plan.planned.size)
        assertTrue(plan.planned.none { it.prayer == "Fajr" })
        assertEquals(0, plan.skippedPast)
    }

    @Test fun `zero reminder fires exactly at prayer time`() {
        val settings = AppSettings(
            fajrSettings = PrayerNotificationSettings(prePrayerReminderMinutes = 0),
            dhuhrSettings = PrayerNotificationSettings(enabled = false),
            asrSettings = PrayerNotificationSettings(enabled = false),
            maghribSettings = PrayerNotificationSettings(enabled = false),
            ishaSettings = PrayerNotificationSettings(enabled = false)
        )
        val plan = FireTimePlanner.plan(date, timings, settings, at(4, 0))
        assertEquals(1, plan.planned.size)
        assertEquals(at(5, 12), plan.planned[0].fireAt)
    }

    @Test fun `past prayers are skipped and counted`() {
        val plan = FireTimePlanner.plan(date, timings, AppSettings(), at(13, 0))
        assertEquals(listOf("Asr", "Maghrib", "Isha"), plan.planned.map { it.prayer })
        assertEquals(2, plan.skippedPast)
    }

    @Test fun `fire moment exactly now counts as past`() {
        // Dhuhr fires 12:40; at exactly 12:40 it must not schedule (already due).
        val plan = FireTimePlanner.plan(date, timings, AppSettings(), at(12, 40))
        assertEquals(listOf("Asr", "Maghrib", "Isha"), plan.planned.map { it.prayer })
        assertEquals(2, plan.skippedPast)
    }

    @Test fun `all past yields empty plan`() {
        val plan = FireTimePlanner.plan(date, timings, AppSettings(), at(23, 0))
        assertTrue(plan.planned.isEmpty())
        assertEquals(5, plan.skippedPast)
    }

    @Test fun `manual time adjustments shift fire moments`() {
        val settings = AppSettings(timeAdjustments = PrayerTimeAdjustments(fajrAdjustment = 60))
        val plan = FireTimePlanner.plan(date, timings, settings, at(4, 0))
        val fajr = plan.planned.first { it.prayer == "Fajr" }
        assertEquals(at(6, 7), fajr.fireAt) // 05:12 + 60 min − 5 min reminder.
        assertEquals("06:12", fajr.timeString)
    }

    @Test fun `large reminder can push fire into previous slot`() {
        val settings = AppSettings(
            dhuhrSettings = PrayerNotificationSettings(prePrayerReminderMinutes = 60)
        )
        val plan = FireTimePlanner.plan(date, timings, settings, at(11, 40))
        val dhuhr = plan.planned.first { it.prayer == "Dhuhr" }
        assertEquals(at(11, 45), dhuhr.fireAt) // 12:45 − 60 min; still future at 11:40.
    }

    @Test fun `replenish is next day at 00-01`() {
        assertEquals(
            ZonedDateTime.of(LocalDate.of(2026, Month.SEPTEMBER, 16), java.time.LocalTime.of(0, 1), zone),
            FireTimePlanner.nextReplenishAt(at(10, 0))
        )
    }

    @Test fun `replenish rolls over new year`() {
        val newYearsEve = ZonedDateTime.of(
            LocalDate.of(2026, Month.DECEMBER, 31), java.time.LocalTime.of(23, 59), zone
        )
        assertEquals(
            ZonedDateTime.of(LocalDate.of(2027, Month.JANUARY, 1), java.time.LocalTime.of(0, 1), zone),
            FireTimePlanner.nextReplenishAt(newYearsEve)
        )
    }
}
