package com.example.prayernotifier.data.notifications

import android.content.Context
import com.example.prayernotifier.R
import com.example.prayernotifier.data.location.AndroidGeocoderProvider
import com.example.prayernotifier.data.location.FusedPositionProvider
import com.example.prayernotifier.data.location.LocationService
import com.example.prayernotifier.data.location.PrefsLocationStorage
import com.example.prayernotifier.data.persistence.PrefsKeyValueStore
import com.example.prayernotifier.data.persistence.SettingsStore
import com.example.prayernotifier.data.persistence.prayerDatabase
import com.example.prayernotifier.i18n.AppLanguage
import com.example.prayernotifier.i18n.prayerNameRes

/** Production wiring. Thin glue only — logic lives in the testable classes. */
class AppGraph(context: Context) {
    private val app = context.applicationContext

    private val database by lazy { prayerDatabase(app) }
    private val locationService by lazy {
        LocationService(
            FusedPositionProvider(app),
            AndroidGeocoderProvider(app),
            PrefsLocationStorage(app)
        )
    }
    private val cache by lazy {
        com.example.prayernotifier.data.persistence.RoomPrayerTimesCache(database.prayerDayDao())
    }
    private val settings by lazy { SettingsStore(PrefsKeyValueStore(app, "prayer_notifier_settings")) }
    private val scheduler by lazy { ExactAlarmScheduler(app, RealAlarmOps(app)) }
    private val notifier by lazy { SystemNotifier(app) }

    val handler by lazy {
        PrayerAlarmHandler(
            locationService, cache, settings, scheduler, notifier,
            texts = LocalizedNotificationTexts(app)
        )
    }
}

/** Notification text in the app's chosen language, resolved at fire time. */
private class LocalizedNotificationTexts(private val app: Context) : NotificationTexts {
    private fun res() = AppLanguage.localizedContext(app).resources
    override fun title(): String = res().getString(R.string.notif_title)
    override fun body(prayer: String, time: String): String =
        res().getString(R.string.notif_body, res().getString(prayerNameRes(prayer)), time)
}
