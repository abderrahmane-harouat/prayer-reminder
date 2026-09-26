package com.example.prayernotifier.data

import android.content.Context
import android.net.ConnectivityManager
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import com.example.prayernotifier.data.connectivity.ConnectivityMonitor
import com.example.prayernotifier.data.connectivity.DefaultConnectivityMonitor
import com.example.prayernotifier.data.connectivity.SystemNetworkProbe
import com.example.prayernotifier.data.connectivity.observeSystemNetworks
import com.example.prayernotifier.data.location.AndroidGeocoderProvider
import com.example.prayernotifier.data.location.FusedPositionProvider
import com.example.prayernotifier.data.location.LocationService
import com.example.prayernotifier.data.location.PrefsLocationStorage
import com.example.prayernotifier.data.notifications.ExactAlarmScheduler
import com.example.prayernotifier.data.notifications.RealAlarmOps
import com.example.prayernotifier.data.persistence.PrefsKeyValueStore
import com.example.prayernotifier.data.persistence.RoomPrayerTimesCache
import com.example.prayernotifier.data.persistence.SettingsStore
import com.example.prayernotifier.data.persistence.prayerDatabase
import java.time.LocalDate
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * UI-layer wiring. Thin glue only — logic lives in the tested data classes.
 * Exposed through [LocalUiGraph] so screens stay free of Android plumbing.
 */
class UiGraph private constructor(app: Context) {
    private val context = app.applicationContext

    /** Work that must outlive any screen, e.g. the offline download. */
    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    val connectivity: ConnectivityMonitor =
        DefaultConnectivityMonitor(SystemNetworkProbe(context))
    val settingsStore = SettingsStore(PrefsKeyValueStore(context, "prayer_notifier_settings"))
    val locationService = LocationService(
        FusedPositionProvider(context),
        AndroidGeocoderProvider(context),
        PrefsLocationStorage(context)
    )

    private val database by lazy { prayerDatabase(context) }
    val cache by lazy { RoomPrayerTimesCache(database.prayerDayDao()) }
    val network = PrayerRepository(AladhanApi.create())
    val repository = PrayerTimesRepository(network, cache, connectivity)
    val scheduler = ExactAlarmScheduler(context, RealAlarmOps(context))
    val offline by lazy { OfflineDownloads(repository, cache, locationService, appScope) }

    /**
     * Re-plans today's alarms from stored data (offline-safe). Called after
     * month loads and after any settings/location change. Mirrors the
     * Flutter app re-scheduling on every settings save.
     */
    suspend fun rescheduleToday(): Boolean {
        val current = locationService.getCurrentSavedLocation() ?: return false
        val today = LocalDate.now()
        val days = cache.load(today.year, today.monthValue, current.latitude, current.longitude)
        val todays = days.firstOrNull {
            it.readableDate == today.format(READABLE)
        } ?: return false
        scheduler.scheduleDay(today, todays.timings, settingsStore.load(), ZonedDateTime.now())
        return true
    }

    companion object {
        private val READABLE: DateTimeFormatter =
            DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH)

        @Volatile
        private var instance: UiGraph? = null

        /**
         * One graph per process, so state shared by screens (offline
         * download, database) survives activity recreation, e.g. a
         * language switch.
         */
        fun get(context: Context): UiGraph =
            instance ?: synchronized(this) {
                instance ?: UiGraph(context.applicationContext).also { instance = it }
            }
    }
}

val LocalUiGraph = compositionLocalOf<UiGraph> { error("UiGraph not provided") }

@Composable
fun UiGraphProvider(content: @Composable () -> Unit) {
    val app = androidx.compose.ui.platform.LocalContext.current.applicationContext
    val graph = remember(app) { UiGraph.get(app) }
    // Live connectivity: re-probe on every network change (Wi-Fi <-> mobile
    // data, VPN, airplane mode) while the UI is alive.
    DisposableEffect(graph) {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val callback = graph.connectivity.observeSystemNetworks(app, scope)
        graph.connectivity.refresh()
        onDispose {
            app.getSystemService(ConnectivityManager::class.java)
                ?.unregisterNetworkCallback(callback)
            scope.cancel()
        }
    }
    CompositionLocalProvider(LocalUiGraph provides graph) {
        content()
    }
}
