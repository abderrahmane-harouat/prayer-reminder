package com.example.prayernotifier.data.location

/** Provides a one-shot device position. Implementations must not touch the UI thread. */
interface PositionProvider {
    suspend fun currentFix(): PositionOutcome
}

/** Reverse-geocodes coords to a display name. Returns null when unavailable. */
interface GeocodeProvider {
    suspend fun placeName(latitude: Double, longitude: Double): String?
}

/**
 * Picks the most relevant place name, mirroring the Flutter fallback chain:
 * locality (city) → administrative area → country → feature name.
 * Pure function so the chain is unit-testable without Android's Geocoder.
 */
fun pickPlaceName(
    locality: String?,
    administrativeArea: String?,
    country: String?,
    featureName: String?
): String? = locality?.takeIf { it.isNotBlank() }
    ?: administrativeArea?.takeIf { it.isNotBlank() }
    ?: country?.takeIf { it.isNotBlank() }
    ?: featureName?.takeIf { it.isNotBlank() }
