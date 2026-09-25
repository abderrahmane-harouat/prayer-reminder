package com.example.prayernotifier.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.prayernotifier.data.PrayerMath
import com.example.prayernotifier.data.UiGraph
import com.example.prayernotifier.data.persistence.AppSettings
import com.example.prayernotifier.data.persistence.CacheStatus
import com.example.prayernotifier.data.persistence.PrayerNotificationSettings
import com.example.prayernotifier.data.persistence.PrayerTimeAdjustments
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class SettingsUiState(
    val loading: Boolean = true,
    val settings: AppSettings = AppSettings(),
    val locationName: String? = null,
    val cacheStatus: CacheStatus? = null,
    val notificationsAllowed: Boolean = true,
    val downloading: Boolean = false,
    val downloadProgress: Int = 0,
    val downloadTotal: Int = 0
)

class SettingsViewModel(private val graph: UiGraph) : ViewModel() {
    private val _state = MutableStateFlow(SettingsUiState())
    val state: StateFlow<SettingsUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.update { it.copy(loading = true) }
            val settings = withContext(Dispatchers.IO) { graph.settingsStore.load() }
            val current = withContext(Dispatchers.IO) {
                graph.locationService.getCurrentSavedLocation()
            }
            val status = if (current != null) {
                withContext(Dispatchers.IO) {
                    graph.cache.cacheStatus(current.latitude, current.longitude)
                }
            } else {
                null
            }
            _state.update {
                it.copy(
                    loading = false,
                    settings = settings,
                    locationName = current?.name,
                    cacheStatus = status
                )
            }
        }
    }

    fun refreshCapabilities(notificationsAllowed: Boolean) {
        _state.update { it.copy(notificationsAllowed = notificationsAllowed) }
    }

    private fun persist(next: AppSettings) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                graph.settingsStore.save(next)
                graph.rescheduleToday()
            }
            _state.update { it.copy(settings = next) }
        }
    }

    fun setHijriOffset(days: Int) {
        persist(_state.value.settings.copy(hijriDateAdjustment = days.coerceIn(-2, 2)))
    }

    fun setAdjustment(prayer: String, minutes: Int) {
        val settings = _state.value.settings
        persist(settings.copy(timeAdjustments = settings.timeAdjustments.with(prayer, minutes)))
    }

    fun adjustmentOf(prayer: String): Int =
        _state.value.settings.timeAdjustments.getAdjustmentForPrayer(prayer)

    fun setPrayerNotifications(prayer: String, next: PrayerNotificationSettings) {
        persist(_state.value.settings.withPrayerSettings(prayer, next))
    }

    /** Same "remind me X min before" for every prayer; on/off stays per prayer. */
    fun setReminderForAll(minutes: Int) {
        var next = _state.value.settings
        PrayerMath.ORDER.forEach { prayer ->
            next = next.withPrayerSettings(
                prayer, next.getSettingsForPrayer(prayer).copy(prePrayerReminderMinutes = minutes)
            )
        }
        persist(next)
    }

    /** One save for a prayer's sheet: its reminder and its time correction. */
    fun savePrayer(prayer: String, notifications: PrayerNotificationSettings, adjustment: Int) {
        val current = _state.value.settings
        persist(
            current.withPrayerSettings(prayer, notifications)
                .copy(timeAdjustments = current.timeAdjustments.with(prayer, adjustment))
        )
    }

    fun downloadOffline() {
        viewModelScope.launch {
            val current = withContext(Dispatchers.IO) {
                graph.locationService.getCurrentSavedLocation()
            } ?: return@launch
            _state.update {
                it.copy(downloading = true, downloadProgress = 0, downloadTotal = 0)
            }
            try {
                withContext(Dispatchers.IO) {
                    graph.repository.downloadOfflineData(
                        current.latitude,
                        current.longitude,
                        onProgress = { done, total ->
                            _state.update {
                                it.copy(downloadProgress = done, downloadTotal = total)
                            }
                        }
                    )
                }
                val status = withContext(Dispatchers.IO) {
                    graph.cache.cacheStatus(current.latitude, current.longitude)
                }
                _state.update { it.copy(cacheStatus = status) }
            } catch (_: Exception) {
                // Card closes; status text explains when nothing is cached.
            } finally {
                _state.update { it.copy(downloading = false) }
            }
        }
    }

    fun prayerNames(): List<String> = PrayerMath.ORDER
}

private fun AppSettings.withPrayerSettings(prayer: String, next: PrayerNotificationSettings) =
    when (prayer) {
        "Fajr" -> copy(fajrSettings = next)
        "Dhuhr" -> copy(dhuhrSettings = next)
        "Asr" -> copy(asrSettings = next)
        "Maghrib" -> copy(maghribSettings = next)
        "Isha" -> copy(ishaSettings = next)
        else -> this
    }

private fun PrayerTimeAdjustments.with(prayer: String, minutes: Int) = when (prayer) {
    "Fajr" -> copy(fajrAdjustment = minutes)
    "Dhuhr" -> copy(dhuhrAdjustment = minutes)
    "Asr" -> copy(asrAdjustment = minutes)
    "Maghrib" -> copy(maghribAdjustment = minutes)
    "Isha" -> copy(ishaAdjustment = minutes)
    else -> this
}
