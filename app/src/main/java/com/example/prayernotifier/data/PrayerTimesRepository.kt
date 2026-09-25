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

    suspend fun downloadOfflineData(
        latitude: Double,
        longitude: Double,
        onProgress: (downloaded: Int, total: Int) -> Unit
    ) {
        val years = RoomPrayerTimesCache.yearsFor(currentYear())
        val total = years.count() * 12

        if (!connectivity.refresh()) {
            // Offline: only acceptable when everything is already saved.
            if (cache.cacheStatus(latitude, longitude).isCached) {
                onProgress(total, total)
                return
            }
            throw PrayerDataException.OfflineNoCache
        }

        var done = 0
        for (year in years) {
            for (month in 1..12) {
                done++
                onProgress(done, total)
                if (cache.load(year, month, latitude, longitude).isNotEmpty()) continue
                try {
                    val fresh = network.getPrayerTimesForMonth(year, month, latitude, longitude)
                    if (fresh.isNotEmpty()) cache.save(fresh, year, month, latitude, longitude)
                    // Small pause so we don't hammer the free API.
                    delay(200)
                } catch (e: Exception) {
                    // Keep going with the next month, like the Flutter app.
                }
            }
        }
    }
}
