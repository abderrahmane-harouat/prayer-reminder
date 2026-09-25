package com.example.prayernotifier.data.persistence

import com.example.prayernotifier.data.HijriDate
import com.example.prayernotifier.data.PrayerDay
import com.example.prayernotifier.data.PrayerTimings
import java.time.Year
import java.util.Locale

/**
 * Offline prayer-times cache backed by Room. Same 2-decimal location matching
 * as before, but rows load per month instead of one giant file.
 * Offline window: 10 years (previous year through current year + 8).
 */
class RoomPrayerTimesCache(
    private val dao: PrayerDayDao,
    private val currentYear: () -> Int = { Year.now().value }
) {
    suspend fun save(days: List<PrayerDay>, year: Int, month: Int, latitude: Double, longitude: Double) {
        val lat = round2(latitude)
        val lng = round2(longitude)
        dao.upsertDays(days.mapIndexed { index, day -> day.toEntity(year, month, index + 1, lat, lng) })
    }

    suspend fun load(year: Int, month: Int, latitude: Double, longitude: Double): List<PrayerDay> =
        dao.getMonth(year, month, round2(latitude), round2(longitude)).map { it.toDomain() }

    /** Removes every cached month for one rounded location. */
    suspend fun clearAllForLocation(latitude: Double, longitude: Double) {
        dao.deleteLocation(round2(latitude), round2(longitude))
    }

    suspend fun hasAnyCachedData(): Boolean = dao.count() > 0

    /** How much of the 10-year offline window is cached for a location. */
    suspend fun cacheStatus(latitude: Double, longitude: Double): CacheStatus {
        val years = yearsFor(currentYear())
        val totalMonths = years.count() * 12
        val cached = dao.cachedMonths(round2(latitude), round2(longitude)).size
        return CacheStatus(
            cachedMonths = cached,
            totalMonths = totalMonths,
            isCached = cached == totalMonths,
            yearsRange = "${years.first} - ${years.last}"
        )
    }

    private fun PrayerDay.toEntity(year: Int, month: Int, day: Int, lat: String, lng: String) =
        PrayerDayEntity(
            year = year, month = month, day = day, latKey = lat, lngKey = lng,
            fajr = timings.fajr, dhuhr = timings.dhuhr, asr = timings.asr,
            maghrib = timings.maghrib, isha = timings.isha,
            hijriDate = hijri.date, hijriDay = hijri.day,
            hijriMonthEn = hijri.monthEn, hijriYear = hijri.year,
            readableDate = readableDate
        )

    private fun PrayerDayEntity.toDomain() = PrayerDay(
        timings = PrayerTimings(fajr, dhuhr, asr, maghrib, isha),
        hijri = HijriDate(hijriDate, hijriDay, hijriMonthEn, hijriYear),
        readableDate = readableDate
    )

    companion object {
        const val YEARS_TO_CACHE = 10

        fun round2(value: Double): String = "%.2f".format(Locale.US, value)

        /** Offline window: previous year through current year + 8 (10 years). */
        fun yearsFor(currentYear: Int): IntRange =
            (currentYear - 1)..(currentYear + YEARS_TO_CACHE - 2)
    }
}
