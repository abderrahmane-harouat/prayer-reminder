package com.example.prayernotifier.data.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.example.prayernotifier.data.PrayerMath
import com.example.prayernotifier.data.PrayerTimings
import com.example.prayernotifier.data.persistence.AppSettings
import java.time.LocalDate
import java.time.ZonedDateTime

/** Pure description of one system alarm: stable ID + intent contents. */
data class AlarmSpec(val requestCode: Int, val action: String, val extras: Map<String, String>)

data class ScheduleReport(val scheduled: Int, val skippedPast: Int, val exactAlarmDenied: Boolean)

interface NotificationScheduler {
    fun scheduleDay(
        date: LocalDate,
        timings: PrayerTimings,
        settings: AppSettings,
        now: ZonedDateTime
    ): ScheduleReport

    fun cancelAll()
}

/** Thin seam over [AlarmManager] so timing is unit-testable. */
interface AlarmOps {
    fun setExactAndAllowWhileIdle(type: Int, triggerMillis: Long, operation: PendingIntent)
    /** Fallback when exact timing is not permitted: may run a few minutes late. */
    fun setAndAllowWhileIdle(type: Int, triggerMillis: Long, operation: PendingIntent)
    fun cancel(operation: PendingIntent)
}

class RealAlarmOps(context: Context) : AlarmOps {
    private val manager = context.applicationContext.getSystemService(AlarmManager::class.java)

    override fun setExactAndAllowWhileIdle(type: Int, triggerMillis: Long, operation: PendingIntent) {
        manager.setExactAndAllowWhileIdle(type, triggerMillis, operation)
    }

    override fun setAndAllowWhileIdle(type: Int, triggerMillis: Long, operation: PendingIntent) {
        manager.setAndAllowWhileIdle(type, triggerMillis, operation)
    }

    override fun cancel(operation: PendingIntent) {
        manager.cancel(operation)
    }
}

/**
 * Schedules timers that each deliver one plain notification — never an
 * alarm-clock alarm (no setAlarmClock, no full-screen intent, no alarm icon).
 * Exact timing is Android's mechanism for firing precisely on time, even in
 * Doze. Where exact timing is not permitted, the same notifications are
 * scheduled inexactly (possibly a few minutes late) rather than dropped.
 */
class ExactAlarmScheduler(
    private val context: Context,
    private val alarms: AlarmOps,
    private val canScheduleExactAlarms: () -> Boolean = { defaultCanScheduleExactAlarms(context) }
) : NotificationScheduler {

    override fun scheduleDay(
        date: LocalDate,
        timings: PrayerTimings,
        settings: AppSettings,
        now: ZonedDateTime
    ): ScheduleReport {
        cancelAll()
        val exact = canScheduleExactAlarms()
        fun set(triggerMillis: Long, operation: PendingIntent) = if (exact) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, operation)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, operation)
        }
        val plan = FireTimePlanner.plan(date, timings, settings, now)
        plan.planned.forEach { item ->
            set(
                item.fireAt.toInstant().toEpochMilli(),
                pendingIntent(prayerAlarmSpec(item.prayer, item.timeString))
            )
        }
        set(
            FireTimePlanner.nextReplenishAt(now).toInstant().toEpochMilli(),
            pendingIntent(REPLENISH_SPEC)
        )
        return ScheduleReport(plan.planned.size, plan.skippedPast, exactAlarmDenied = !exact)
    }

    override fun cancelAll() {
        PrayerMath.ORDER.forEach { cancelSpec(prayerAlarmSpec(it, "")) }
        cancelSpec(REPLENISH_SPEC)
    }

    private fun cancelSpec(spec: AlarmSpec) {
        alarms.cancel(pendingIntent(spec))
    }

    private fun pendingIntent(spec: AlarmSpec): PendingIntent {
        val intent = Intent(context.applicationContext, PrayerAlarmReceiver::class.java)
            .setAction(spec.action)
        spec.extras.forEach { (key, value) -> intent.putExtra(key, value) }
        return PendingIntent.getBroadcast(
            context.applicationContext,
            spec.requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    companion object {
        const val ACTION_PRAYER_ALARM = "com.example.prayernotifier.ACTION_PRAYER_ALARM"
        const val ACTION_REPLENISH = "com.example.prayernotifier.ACTION_REPLENISH"
        const val EXTRA_PRAYER = "prayer"
        const val EXTRA_TIME = "time"
        const val REQUEST_REPLENISH = 100

        val REPLENISH_SPEC = AlarmSpec(REQUEST_REPLENISH, ACTION_REPLENISH, emptyMap())

        /** Stable IDs 1..5 (Fajr..Isha), so re-scheduling replaces cleanly. */
        fun prayerAlarmSpec(prayer: String, timeString: String): AlarmSpec = AlarmSpec(
            requestCode = PrayerMath.ORDER.indexOf(prayer) + 1,
            action = ACTION_PRAYER_ALARM,
            extras = mapOf(EXTRA_PRAYER to prayer, EXTRA_TIME to timeString)
        )

        fun notificationIdFor(prayer: String): Int =
            PrayerMath.ORDER.indexOf(prayer).takeIf { it >= 0 }?.plus(1)
                ?: prayer.hashCode()

        private fun defaultCanScheduleExactAlarms(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
            return context.applicationContext.getSystemService(AlarmManager::class.java)
                ?.canScheduleExactAlarms() == true
        }
    }
}
