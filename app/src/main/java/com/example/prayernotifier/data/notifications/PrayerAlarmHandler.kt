package com.example.prayernotifier.data.notifications

import com.example.prayernotifier.data.location.LocationService
import com.example.prayernotifier.data.persistence.RoomPrayerTimesCache
import com.example.prayernotifier.data.persistence.SettingsStore
import java.time.Year
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Notification wording, so the handler stays free of Android resources. */
interface NotificationTexts {
    fun title(): String
    fun body(prayer: String, time: String): String
}

object EnglishNotificationTexts : NotificationTexts {
    override fun title() = "Prayer time"
    override fun body(prayer: String, time: String) = "Time for $prayer prayer · $time"
}

/**
 * Answers the receiver's two questions using stored data only (offline-safe):
 * an alarm fired → show its notification; the day changed (replenish alarm or
 * reboot) → re-plan today's alarms from the database.
 */
class PrayerAlarmHandler(
    private val location: LocationService,
    private val cache: RoomPrayerTimesCache,
    private val settings: SettingsStore,
    private val scheduler: NotificationScheduler,
    private val notifier: Notifier,
    private val now: () -> ZonedDateTime = { ZonedDateTime.now() },
    private val currentYear: () -> Int = { Year.now().value },
    private val texts: NotificationTexts = EnglishNotificationTexts
) {
    suspend fun onAlarmFired(prayer: String, timeString: String) {
        notifier.showPrayerNotification(
            ExactAlarmScheduler.notificationIdFor(prayer),
            texts.title(),
            texts.body(prayer, timeString)
        )
    }

    /** Re-plans today. Returns false when there is nothing to plan with. */
    suspend fun onDayChanged(): Boolean {
        val moment = now()
        val today = moment.toLocalDate()
        val current = location.getCurrentSavedLocation() ?: return false
        val days = cache.load(today.year, today.monthValue, current.latitude, current.longitude)
        val todays = days.firstOrNull { it.readableDate == today.format(READABLE) } ?: return false
        scheduler.scheduleDay(today, todays.timings, settings.load(), moment)
        return true
    }

    companion object {
        private val READABLE: DateTimeFormatter =
            DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH)
    }
}
