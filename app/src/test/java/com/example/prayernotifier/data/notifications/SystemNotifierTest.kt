package com.example.prayernotifier.data.notifications

import android.app.NotificationManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class SystemNotifierTest {

    private lateinit var context: Context
    private lateinit var notifier: SystemNotifier

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        notifier = SystemNotifier(context)
    }

    private fun manager(): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    @Test fun `channel exists with custom sound and high importance`() {
        val channel = manager().getNotificationChannel(SystemNotifier.CHANNEL_ID)
        assertNotNull(channel)
        assertEquals(NotificationManager.IMPORTANCE_HIGH, channel.importance)
        assertNotNull(channel.sound)
        assertTrue(channel.sound.toString().contains("raw/notification"))
    }

    @Test fun `posts a plain notification with title and body`() {
        notifier.showPrayerNotification(4, "Prayer time", "Time for Maghrib prayer · 18:52")

        val posted = manager().activeNotifications
        assertEquals(1, posted.size)
        assertEquals(4, posted[0].id)
        val extras = posted[0].notification.extras
        assertEquals("Prayer time", extras.getString("android.title"))
        assertEquals("Time for Maghrib prayer · 18:52", extras.getString("android.text"))
    }

    @Test fun `no full-screen alarm intent attached`() {
        notifier.showPrayerNotification(4, "Prayer time", "Time for Maghrib prayer · 18:52")

        val posted = manager().activeNotifications[0].notification
        assertEquals(null, posted.fullScreenIntent)
    }

    @Test fun `each prayer keeps its own notification slot`() {
        notifier.showPrayerNotification(1, "Prayer time", "Time for Fajr prayer · 05:12")
        notifier.showPrayerNotification(4, "Prayer time", "Time for Maghrib prayer · 18:52")

        assertEquals(2, manager().activeNotifications.size)
    }
}
