package com.example.prayernotifier.data

import com.example.prayernotifier.data.location.CurrentLocation
import com.example.prayernotifier.data.location.LocationService
import com.example.prayernotifier.data.persistence.CacheStatus
import com.example.prayernotifier.data.persistence.RoomPrayerTimesCache
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** What every screen shows about offline data, from one source. */
data class OfflineState(
    /** The place the status and any download refer to. */
    val place: CurrentLocation? = null,
    val status: CacheStatus? = null,
    val running: Boolean = false,
    val done: Int = 0,
    val total: Int = 0,
    /** Outcome of the last finished run; cleared by [OfflineDownloads.consumeResult]. */
    val result: OfflineResult? = null
)

sealed interface OfflineResult {
    /** Everything in the range is saved. */
    data object Complete : OfflineResult
    /** Some months could not be fetched; running again retries only those. */
    data class Partial(val failed: Int) : OfflineResult
    data object NoInternet : OfflineResult
}

/**
 * The single offline download for the whole app. Home and Settings both
 * observe [state] and call [start], so they always show the same progress
 * and can never start two downloads. Runs in an app-lifetime [scope], so it
 * keeps going when you switch screens or the activity is recreated.
 */
class OfflineDownloads(
    private val repository: PrayerTimesRepository,
    private val cache: RoomPrayerTimesCache,
    private val locations: LocationService,
    private val scope: CoroutineScope
) {
    private val _state = MutableStateFlow(OfflineState())
    val state: StateFlow<OfflineState> = _state.asStateFlow()

    /** Re-read the current place and what's saved for it (e.g. after a location change). */
    fun refresh() {
        scope.launch { refreshNow() }
    }

    fun start() {
        // Claim the run synchronously so double taps can't start two downloads.
        var claimed = false
        _state.update {
            if (it.running) {
                it
            } else {
                claimed = true
                it.copy(running = true, done = 0, total = 0, result = null)
            }
        }
        if (!claimed) return
        scope.launch {
            val place = locations.getCurrentSavedLocation()
            if (place == null) {
                _state.update { it.copy(running = false) }
                return@launch
            }
            _state.update { it.copy(place = place) }
            val result = try {
                val outcome = repository.downloadOfflineData(place.latitude, place.longitude) { done, total ->
                    _state.update { it.copy(done = done, total = total) }
                }
                if (outcome.failed > 0) OfflineResult.Partial(outcome.failed) else OfflineResult.Complete
            } catch (e: PrayerDataException.OfflineNoCache) {
                OfflineResult.NoInternet
            }
            val status = cache.cacheStatus(place.latitude, place.longitude)
            _state.update { it.copy(running = false, status = status, result = result) }
            // The place may have changed while downloading: show the current one.
            refreshNow()
        }
    }

    fun consumeResult() = _state.update { it.copy(result = null) }

    private suspend fun refreshNow() {
        val place = locations.getCurrentSavedLocation() ?: return
        val status = cache.cacheStatus(place.latitude, place.longitude)
        _state.update { current ->
            // A running download reports its own place; don't swap it mid-run.
            if (current.running) current else current.copy(place = place, status = status)
        }
    }
}
