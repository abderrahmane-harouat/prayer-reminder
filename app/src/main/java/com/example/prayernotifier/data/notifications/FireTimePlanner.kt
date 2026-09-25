package com.example.prayernotifier.data.notifications

import com.example.prayernotifier.data.PrayerMath
import com.example.prayernotifier.data.PrayerTimings
import com.example.prayernotifier.data.persistence.AppSettings
import java.time.LocalDate
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

/**
 * One notification to fire: which prayer, at what exact moment, and how
 * many minutes before the prayer that is (0 = at the prayer time).
 */
data class PlannedNotification(
    val prayer: String,
    val fireAt: ZonedDateTime,
    val timeString: String,
    val leadMinutes: Int = 0
)

data class DayPlan(val planned: List<PlannedNotification>, val skippedPast: Int)

/**
 * Pure scheduling math: per-prayer enable flags + "remind me X minutes
 * before" → exact fire moments. Past moments are skipped and counted.
 */
object FireTimePlanner {
    private val TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm")

    fun plan(
        date: LocalDate,
        timings: PrayerTimings,
        settings: AppSettings,
        now: ZonedDateTime
    ): DayPlan {
        val planned = mutableListOf<PlannedNotification>()
        var skipped = 0
        for (prayer in PrayerMath.ORDER) {
            val prayerSettings = settings.getSettingsForPrayer(prayer)
            if (!prayerSettings.enabled) continue
            val at = PrayerMath
                .dateTimeFor(timings, settings.timeAdjustments, prayer, date)
                .atZone(now.zone)
            val fireAt = at.minusMinutes(prayerSettings.prePrayerReminderMinutes.toLong())
            if (!fireAt.isAfter(now)) {
                skipped++
                continue
            }
            planned += PlannedNotification(
                prayer, fireAt, at.format(TIME_FORMAT), prayerSettings.prePrayerReminderMinutes
            )
        }
        return DayPlan(planned, skipped)
    }

    /** Daily re-plan moment: 00:01 the next day, so tomorrow is always covered. */
    fun nextReplenishAt(now: ZonedDateTime): ZonedDateTime =
        now.toLocalDate().plusDays(1).atStartOfDay(now.zone).plusMinutes(1)
}
