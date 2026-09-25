package com.example.prayernotifier.data.persistence

import androidx.room.Entity

/**
 * One cached day. Rows are keyed by date + rounded location, so months are
 * read with a single query and only the requested rows ever load into memory
 * (unlike the old whole-file SharedPreferences box).
 */
@Entity(
    tableName = "prayer_days",
    primaryKeys = ["year", "month", "day", "latKey", "lngKey"]
)
data class PrayerDayEntity(
    val year: Int,
    val month: Int,
    val day: Int,
    val latKey: String,
    val lngKey: String,
    val fajr: String,
    val dhuhr: String,
    val asr: String,
    val maghrib: String,
    val isha: String,
    val hijriDate: String,
    val hijriDay: String,
    val hijriMonthEn: String,
    val hijriYear: String,
    val readableDate: String
)
