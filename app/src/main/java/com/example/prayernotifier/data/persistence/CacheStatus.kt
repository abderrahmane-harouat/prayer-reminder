package com.example.prayernotifier.data.persistence

data class CacheStatus(
    val cachedMonths: Int,
    val totalMonths: Int,
    val isCached: Boolean,
    val yearsRange: String
)
