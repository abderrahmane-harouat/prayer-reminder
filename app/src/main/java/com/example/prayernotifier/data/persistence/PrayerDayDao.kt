package com.example.prayernotifier.data.persistence

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert

data class YearMonth(val year: Int, val month: Int)

@Dao
interface PrayerDayDao {

    @Upsert
    suspend fun upsertDays(days: List<PrayerDayEntity>)

    @Query(
        """SELECT * FROM prayer_days
           WHERE year = :year AND month = :month AND latKey = :lat AND lngKey = :lng
           ORDER BY day ASC"""
    )
    suspend fun getMonth(year: Int, month: Int, lat: String, lng: String): List<PrayerDayEntity>

    @Query(
        """SELECT DISTINCT year, month FROM prayer_days
           WHERE latKey = :lat AND lngKey = :lng"""
    )
    suspend fun cachedMonths(lat: String, lng: String): List<YearMonth>

    @Query("DELETE FROM prayer_days WHERE latKey = :lat AND lngKey = :lng")
    suspend fun deleteLocation(lat: String, lng: String)

    @Query("SELECT COUNT(*) FROM prayer_days")
    suspend fun count(): Int
}
