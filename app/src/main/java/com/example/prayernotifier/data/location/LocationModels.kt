package com.example.prayernotifier.data.location

import kotlinx.serialization.Serializable

data class LatLng(val latitude: Double, val longitude: Double)

/** Persisted "current location" (coords + reverse-geocoded name). */
@Serializable
data class CurrentLocation(
    val name: String,
    val latitude: Double,
    val longitude: Double
)

/** A saved place. `savedAtEpochMs` replaces Flutter's ISO `savedAt` string. */
@Serializable
data class SavedLocation(
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val savedAtEpochMs: Long
)

/** Typed failures mirroring the Flutter `LocationService` error cases. */
sealed class LocationException(message: String) : Exception(message) {
    data object ServiceDisabled : LocationException("Location services are disabled.")
    data object PermissionDenied : LocationException("Location permissions are denied.")
    data object NoFix : LocationException("Could not obtain a location fix.")
}

/** Raw outcome from a position provider; mapped to [LocationException] by the service. */
sealed interface PositionOutcome {
    data class Fix(val value: LatLng) : PositionOutcome
    data object ServiceDisabled : PositionOutcome
    data object PermissionMissing : PositionOutcome
    data object NoFix : PositionOutcome
}
