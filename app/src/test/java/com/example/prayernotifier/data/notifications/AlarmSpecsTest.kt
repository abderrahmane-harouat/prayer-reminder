package com.example.prayernotifier.data.notifications

import org.junit.Assert.assertEquals
import org.junit.Test

class AlarmSpecsTest {

    @Test fun `prayer request codes are stable 1 to 5`() {
        val codes = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha").map {
            ExactAlarmScheduler.prayerAlarmSpec(it, "00:00").requestCode
        }
        assertEquals(listOf(1, 2, 3, 4, 5), codes)
    }

    @Test fun `replenish has its own stable code`() {
        assertEquals(100, ExactAlarmScheduler.REPLENISH_SPEC.requestCode)
        assertEquals(
            ExactAlarmScheduler.ACTION_REPLENISH,
            ExactAlarmScheduler.REPLENISH_SPEC.action
        )
    }

    @Test fun `prayer spec carries action and extras`() {
        val spec = ExactAlarmScheduler.prayerAlarmSpec("Maghrib", "18:52")
        assertEquals(ExactAlarmScheduler.ACTION_PRAYER_ALARM, spec.action)
        assertEquals("Maghrib", spec.extras[ExactAlarmScheduler.EXTRA_PRAYER])
        assertEquals("18:52", spec.extras[ExactAlarmScheduler.EXTRA_TIME])
    }

    @Test fun `notification ids match request codes`() {
        assertEquals(1, ExactAlarmScheduler.notificationIdFor("Fajr"))
        assertEquals(4, ExactAlarmScheduler.notificationIdFor("Maghrib"))
        assertEquals(5, ExactAlarmScheduler.notificationIdFor("Isha"))
    }
}
