package com.example.prayernotifier.data

import com.example.prayernotifier.data.connectivity.ConnectivityMonitor
import com.example.prayernotifier.data.persistence.RoomPrayerTimesCache
import kotlinx.coroutines.delay
import java.time.Year

sealed class PrayerDataException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    data object OfflineNoCache :
        PrayerDataException("No internet connection and no saved data for this month.")

    class FetchFailed(cause: Throwable) :
        PrayerDataException("Could not download prayer times.", cause)
}

/**
 * The brain: joins network + database + connectivity.
 * - One month: saved data first, download only when missing, clear error
 *   when offline with nothing saved.
 * - Bulk: downloads the whole 10-year offline window once, skipping months
 *   already saved, reporting progress. Nothing happens without the user
 *   asking — no background sync, ever.
 */
class PrayerTimesRepository(
    private val network: PrayerRepository,
    private val cache: RoomPrayerTimesCache,
    private val connectivity: ConnectivityMonitor,
    private val currentYear: () -> Int = { Year.now().value }
) {
    suspend fun getPrayerTimesForMonth(
        year: Int,
        month: Int,
        latitude: Double,
        longitude: Double
    ): List<PrayerDay> {
        val cached = cache.load(year, month, latitude, longitude)
        if (cached.isNotEmpty()) return cached

        if (!connectivity.refresh()) throw PrayerDataException.OfflineNoCache
        try {
            val fresh = network.getPrayerTimesForMonth(year, month, latitude, longitude)
            if (fresh.isNotEmpty()) cache.save(fresh, year, month, latitude, longitude)
            return fresh
        } catch (e: Exception) {
            throw PrayerDataException.FetchFailed(e)
        }
    }

    /**
     * Saves every month of the offline range that isn't saved yet. The
     * missing months are found first (local only), so progress runs from 0
     * to the number that really needs downloading. Months that fail are
     * counted, not hidden; running again retries just those.
     */
    suspend fun downloadOfflineData(
        latitude: Double,
        longitude: Double,
        onProgress: (downloaded: Int, total: Int) -> Unit
    ): DownloadResult {
        val missing = RoomPrayerTimesCache.yearsFor(currentYear())
            .flatMap { year -> (1..12).map { month -> year to month } }
            .filter { (year, month) -> cache.load(year, month, latitude, longitude).isEmpty() }
        if (missing.isEmpty()) return DownloadResult(downloaded = 0, failed = 0)
        if (!connectivity.refresh()) throw PrayerDataException.OfflineNoCache

        var downloaded = 0
        var failed = 0
        onProgress(0, missing.size)
        missing.forEachIndexed { index, (year, month) ->
            try {
                val fresh = network.getPrayerTimesForMonth(year, month, latitude, longitude)
                if (fresh.isNotEmpty()) {
                    cache.save(fresh, year, month, latitude, longitude)
                    downloaded++
                } else {
                    failed++
                }
            } catch (e: Exception) {
                failed++
            }
            onProgress(index + 1, missing.size)
            // Small pause so we don't hammer the free API.
            if (index < missing.lastIndex) delay(150)
        }
        return DownloadResult(downloaded, failed)
    }
}

/** Outcome of one offline download run. */
data class DownloadResult(val downloaded: Int, val failed: Int)
