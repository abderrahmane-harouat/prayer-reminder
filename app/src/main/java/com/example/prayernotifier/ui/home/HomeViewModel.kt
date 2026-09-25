package com.example.prayernotifier.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.prayernotifier.data.PrayerDataException
import com.example.prayernotifier.data.PrayerDay
import com.example.prayernotifier.data.UiGraph
import com.example.prayernotifier.data.connectivity.NetworkKind
import com.example.prayernotifier.data.connectivity.canReachPrayerServer
import com.example.prayernotifier.data.location.CurrentLocation
import com.example.prayernotifier.data.location.LocationException
import com.example.prayernotifier.data.location.SavedLocation
import com.example.prayernotifier.data.persistence.AppSettings
import com.example.prayernotifier.data.persistence.CacheStatus
import java.time.LocalDate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

sealed interface HomeError {
    data class LocationRequired(val cause: LocationCause) : HomeError
    data object OfflineNoData : HomeError
    data class LoadFailed(val message: String) : HomeError
}

enum class LocationCause {
    /** System dialog can still pop up. */
    PermissionRequestable,
    /** User picked "Don't allow" twice — only app settings helps now. */
    PermissionLocked,
    /** Device location services are switched off. */
    ServiceDisabled,
    /** No GPS fix available. */
    NoFix
}

/**
 * One-shot messages for things that happen while data is already on screen
 * (where a full-screen error would wipe the prayer times away).
 */
sealed interface HomeNotice {
    data class LocationUpdated(val name: String) : HomeNotice
    data class LocationFailed(val cause: LocationCause) : HomeNotice
    data object LoadFailed : HomeNotice
    data class Connected(val kind: NetworkKind) : HomeNotice
    /** A network is up, but the prayer-times server doesn't answer. */
    data class ServerUnreachable(val kind: NetworkKind) : HomeNotice
    data object Offline : HomeNotice
}

data class HomeUiState(
    val loading: Boolean = true,
    /** Blank until named; the UI shows a localized "Current location". */
    val locationName: String = "",
    val isOnline: Boolean = true,
    val network: NetworkKind = NetworkKind.Other,
    val checkingConnection: Boolean = false,
    val days: List<PrayerDay> = emptyList(),
    val selectedDate: LocalDate = LocalDate.now(),
    val settings: AppSettings = AppSettings(),
    val error: HomeError? = null,
    val downloading: Boolean = false,
    val downloadProgress: Int = 0,
    val downloadTotal: Int = 0,
    val savedLocations: List<SavedLocation> = emptyList(),
    val askForPermission: Boolean = false,
    /** A location fix is in progress (can take a few seconds outdoors). */
    val locating: Boolean = false,
    /** Offline-data coverage for the current place; null until loaded. */
    val cacheStatus: CacheStatus? = null,
    val notice: HomeNotice? = null
)

class HomeViewModel(private val graph: UiGraph) : ViewModel() {
    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    private var current: CurrentLocation? = null

    init {
        viewModelScope.launch {
            graph.connectivity.kind.collect { kind ->
                val cameBack = _state.value.network == NetworkKind.None && kind != NetworkKind.None
                _state.update { it.copy(isOnline = kind != NetworkKind.None, network = kind) }
                // Back online after an offline failure: load again by itself.
                if (cameBack && _state.value.error != null) start()
            }
        }
        start()
    }

    fun start() {
        viewModelScope.launch {
            _state.update { it.copy(loading = true, error = null) }
            val settings = withContext(Dispatchers.IO) { graph.settingsStore.load() }
            _state.update { it.copy(settings = settings) }
            val cached = withContext(Dispatchers.IO) {
                graph.locationService.getCurrentSavedLocation()
            }
            if (cached != null) {
                current = cached
                _state.update { it.copy(locationName = cached.name) }
                loadMonth(itSelected())
            } else {
                obtainFreshLocation()
            }
        }
    }

    fun retry() = start()

    /** System dialog answered (first-run auto request or tap-initiated). */
    fun onPermissionResult(granted: Boolean, locked: Boolean) {
        _state.update { it.copy(askForPermission = false) }
        if (granted) {
            viewModelScope.launch { obtainFreshLocation() }
        } else {
            val cause = if (locked) {
                LocationCause.PermissionLocked
            } else {
                LocationCause.PermissionRequestable
            }
            _state.update {
                it.copy(loading = false, error = HomeError.LocationRequired(cause))
            }
        }
    }

    /** Permission can no longer pop up — point the user at app settings. */
    fun onPermissionPermanentlyDenied() {
        _state.update {
            it.copy(
                loading = false,
                error = HomeError.LocationRequired(LocationCause.PermissionLocked)
            )
        }
    }

    /**
     * Called when Home becomes visible: reload settings and recover whenever
     * the location permission is now granted — whatever the previous error
     * was (granted from a system page, adb, or a fresh dialog answer).
     */
    fun onResumed(locationPermissionGranted: Boolean) {
        refreshSettings()
        if (locationPermissionGranted &&
            _state.value.error is HomeError.LocationRequired
        ) {
            viewModelScope.launch { obtainFreshLocation() }
        }
    }

    fun refreshLocation() {
        viewModelScope.launch { obtainFreshLocation() }
    }

    fun selectDate(date: LocalDate) {
        val before = _state.value.selectedDate
        if (before == date) return
        _state.update { it.copy(selectedDate = date, error = null) }
        if (before.year != date.year || before.monthValue != date.monthValue) {
            viewModelScope.launch { loadMonth(date) }
        }
    }

    /** Instant when today's month is already loaded (the usual case). */
    fun goToToday() = selectDate(LocalDate.now())

    fun consumeNotice() = _state.update { it.copy(notice = null) }

    /** Refresh what's saved offline for the current place (same data as Settings). */
    fun loadCacheStatus() {
        val loc = current ?: return
        viewModelScope.launch {
            val status = withContext(Dispatchers.IO) {
                graph.cache.cacheStatus(loc.latitude, loc.longitude)
            }
            _state.update { it.copy(cacheStatus = status) }
        }
    }

    /**
     * The header's connection button: re-read the network, then really try
     * the prayer-times server over it. Reloads when that works and the
     * screen was showing an error.
     */
    fun checkConnection() {
        if (_state.value.checkingConnection) return
        viewModelScope.launch {
            _state.update { it.copy(checkingConnection = true) }
            val online = withContext(Dispatchers.IO) { graph.connectivity.refresh() }
            val kind = graph.connectivity.kind.value
            val notice = when {
                !online -> HomeNotice.Offline
                canReachPrayerServer() -> HomeNotice.Connected(kind)
                else -> HomeNotice.ServerUnreachable(kind)
            }
            _state.update { it.copy(checkingConnection = false, notice = notice) }
            if (notice is HomeNotice.Connected && _state.value.error != null) start()
        }
    }

    fun selectSavedLocation(location: SavedLocation) {
        viewModelScope.launch {
            _state.update { it.copy(loading = true, error = null) }
            val updated = withContext(Dispatchers.IO) {
                graph.locationService.selectSavedLocation(location)
            }
            current = updated
            _state.update {
                it.copy(locationName = updated.name, selectedDate = LocalDate.now())
            }
            loadMonth(LocalDate.now())
        }
    }

    fun loadSavedLocations() {
        viewModelScope.launch {
            val saved = withContext(Dispatchers.IO) {
                graph.locationService.getSavedLocations()
            }
            _state.update { it.copy(savedLocations = saved) }
        }
    }

    fun refreshSettings() {
        viewModelScope.launch {
            val settings = withContext(Dispatchers.IO) { graph.settingsStore.load() }
            _state.update { it.copy(settings = settings) }
        }
    }

    fun downloadOffline() {
        val loc = current ?: return
        viewModelScope.launch {
            _state.update {
                it.copy(downloading = true, downloadProgress = 0, downloadTotal = 0)
            }
            try {
                withContext(Dispatchers.IO) {
                    graph.repository.downloadOfflineData(
                        loc.latitude,
                        loc.longitude,
                        onProgress = { done, total ->
                            _state.update {
                                it.copy(downloadProgress = done, downloadTotal = total)
                            }
                        }
                    )
                }
            } catch (_: Exception) {
                // Progress closes; the offline status below explains what's missing.
            } finally {
                _state.update { it.copy(downloading = false) }
                loadCacheStatus()
            }
        }
    }

    private fun itSelected(): LocalDate = _state.value.selectedDate

    /**
     * Fresh GPS fix → name → load times. With prayer times already on screen
     * the page stays put: the header shows "Locating…" and the outcome
     * arrives as a [HomeNotice]; on first run failures are full-screen.
     */
    private suspend fun obtainFreshLocation() {
        val hasData = _state.value.days.isNotEmpty()
        _state.update {
            if (hasData) it.copy(locating = true) else it.copy(loading = true, error = null, locating = true)
        }
        fun fail(cause: LocationCause) = _state.update {
            if (hasData) {
                it.copy(locating = false, notice = HomeNotice.LocationFailed(cause))
            } else {
                it.copy(loading = false, locating = false, error = HomeError.LocationRequired(cause))
            }
        }
        try {
            val fresh = withContext(Dispatchers.IO) {
                graph.locationService.refreshLocation()
            }
            current = fresh
            _state.update {
                it.copy(
                    locationName = fresh.name,
                    locating = false,
                    notice = if (hasData) HomeNotice.LocationUpdated(fresh.name) else it.notice
                )
            }
            loadMonth(itSelected())
        } catch (e: LocationException.PermissionDenied) {
            _state.update { it.copy(loading = false, locating = false, askForPermission = true) }
        } catch (e: LocationException.ServiceDisabled) {
            fail(LocationCause.ServiceDisabled)
        } catch (e: LocationException.NoFix) {
            fail(LocationCause.NoFix)
        } catch (e: Exception) {
            _state.update {
                if (hasData) {
                    it.copy(locating = false, notice = HomeNotice.LoadFailed)
                } else {
                    it.copy(loading = false, locating = false, error = HomeError.LoadFailed(e.message.orEmpty()))
                }
            }
        }
    }

    private suspend fun loadMonth(forDate: LocalDate) {
        val loc = current
        if (loc == null) {
            _state.update {
                it.copy(
                    loading = false,
                    error = HomeError.LocationRequired(LocationCause.PermissionRequestable)
                )
            }
            return
        }
        _state.update { it.copy(loading = true, error = null) }
        try {
            val days = withContext(Dispatchers.IO) {
                graph.repository.getPrayerTimesForMonth(
                    forDate.year, forDate.monthValue, loc.latitude, loc.longitude
                )
            }
            _state.update { it.copy(loading = false, days = days) }
            if (forDate == LocalDate.now()) {
                withContext(Dispatchers.IO) { graph.rescheduleToday() }
            }
        } catch (e: PrayerDataException.OfflineNoCache) {
            _state.update {
                it.copy(
                    loading = false,
                    error = HomeError.OfflineNoData,
                    notice = if (it.days.isNotEmpty()) HomeNotice.LoadFailed else it.notice
                )
            }
        } catch (e: Exception) {
            _state.update {
                it.copy(
                    loading = false,
                    error = HomeError.LoadFailed(e.message.orEmpty()),
                    notice = if (it.days.isNotEmpty()) HomeNotice.LoadFailed else it.notice
                )
            }
        }
    }
}
