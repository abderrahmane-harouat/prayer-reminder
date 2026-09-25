package com.example.prayernotifier.data

import kotlinx.serialization.Serializable

/** Domain models — mirrors the Flutter app's `lib/models/prayer_times.dart`. */
@Serializable
data class PrayerTimings(
    val fajr: String,
    val dhuhr: String,
    val asr: String,
    val maghrib: String,
    val isha: String
)

@Serializable
data class HijriDate(
    val date: String,
    val day: String,
    val monthEn: String,
    val year: String
)

@Serializable
data class PrayerDay(
    val timings: PrayerTimings,
    val hijri: HijriDate,
    val readableDate: String
)
