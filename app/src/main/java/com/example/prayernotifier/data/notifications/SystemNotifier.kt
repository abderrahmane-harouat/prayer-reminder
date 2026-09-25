package com.example.prayernotifier.data.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.prayernotifier.R
import com.example.prayernotifier.i18n.AppLanguage

interface Notifier {
    fun showPrayerNotification(id: Int, title: String, body: String)
}

/**
 * Posts plain notifications — no full-screen alarm UI, no looping sound.
 * One notification per prayer, custom sound, high importance for heads-up.
 */
class SystemNotifier(context: Context) : Notifier {
    private val app = context.applicationContext
    private val manager = NotificationManagerCompat.from(app)

    init {
        createChannel()
    }

    private fun createChannel() {
        val sound = Uri.parse("android.resource://${app.packageName}/raw/notification")
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val res = AppLanguage.localizedContext(app).resources
        val channel = NotificationChannel(
            CHANNEL_ID, res.getString(R.string.channel_name), NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = res.getString(R.string.channel_desc)
            setSound(sound, audio)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    override fun showPrayerNotification(id: Int, title: String, body: String) {
        val notification = NotificationCompat.Builder(app, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_prayer)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setShowWhen(true)
            .build()
        manager.notify(id, notification)
    }

    companion object {
        const val CHANNEL_ID = "prayer_notifications"
    }
}
