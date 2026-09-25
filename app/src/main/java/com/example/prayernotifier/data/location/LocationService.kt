package com.example.prayernotifier.data.location

/**
 * Orchestrates position + reverse-geocode + persistence.
 * Mirrors the Flutter `LocationService` flows (`_updateLocation`,
 * `_selectSavedLocation`, instant offline startup via saved current location).
 */
class LocationService(
    private val positions: PositionProvider,
    private val geocoder: GeocodeProvider,
    private val storage: LocationStorage
) {
    /** One-shot fix, or throws [LocationException]. Never returns null. */
    suspend fun determinePosition(): LatLng = when (val outcome = positions.currentFix()) {
        is PositionOutcome.Fix -> outcome.value
        PositionOutcome.ServiceDisabled -> throw LocationException.ServiceDisabled
        PositionOutcome.PermissionMissing -> throw LocationException.PermissionDenied
        PositionOutcome.NoFix -> throw LocationException.NoFix
    }

    suspend fun getPlaceName(latitude: Double, longitude: Double): String? =
        geocoder.placeName(latitude, longitude)

    /**
     * Full refresh: fix → reverse-geocode → persist current + cached name +
     * saved-list entry (same-area entries are updated, not duplicated).
     * When no place name resolves (offline geocoder, open sea) the fix is
     * still saved under its coordinates, so the new location sticks.
     */
    suspend fun refreshLocation(nowEpochMs: Long = System.currentTimeMillis()): CurrentLocation {
        val pos = determinePosition()
        val name = getPlaceName(pos.latitude, pos.longitude)
            ?: coordinateLabel(pos.latitude, pos.longitude)
        val current = CurrentLocation(name, pos.latitude, pos.longitude)
        storage.saveCurrentLocation(current)
        storage.cacheLocationName(name)
        storage.saveLocation(SavedLocation(name, pos.latitude, pos.longitude, nowEpochMs))
        return current
    }

    /** Switch to a previously saved place (persists it as current). */
    suspend fun selectSavedLocation(value: SavedLocation): CurrentLocation {
        val current = CurrentLocation(value.name, value.latitude, value.longitude)
        storage.saveCurrentLocation(current)
        storage.cacheLocationName(value.name)
        return current
    }

    suspend fun getCurrentSavedLocation(): CurrentLocation? = storage.getCurrentLocation()
    suspend fun getSavedLocations(): List<SavedLocation> = storage.getSavedLocations()
    suspend fun deleteLocation(latitude: Double, longitude: Double) =
        storage.deleteLocation(latitude, longitude)
    suspend fun getCachedLocationName(): String? = storage.getCachedLocationName()
}

/** "36.75°N, 3.06°E" — a readable name for a fix the geocoder can't name. */
fun coordinateLabel(latitude: Double, longitude: Double): String {
    val lat = String.format(java.util.Locale.ROOT, "%.2f°%s", kotlin.math.abs(latitude), if (latitude >= 0) "N" else "S")
    val lng = String.format(java.util.Locale.ROOT, "%.2f°%s", kotlin.math.abs(longitude), if (longitude >= 0) "E" else "W")
    return "$lat, $lng"
}
