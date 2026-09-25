package com.example.prayernotifier.data.location

import android.content.Context
import androidx.core.content.edit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/** Persistence for current/saved locations and the cached place name. */
interface LocationStorage {
    suspend fun saveCurrentLocation(value: CurrentLocation)
    suspend fun getCurrentLocation(): CurrentLocation?
    suspend fun getSavedLocations(): List<SavedLocation>
    suspend fun saveLocation(value: SavedLocation)
    suspend fun deleteLocation(latitude: Double, longitude: Double)
    suspend fun cacheLocationName(name: String)
    suspend fun getCachedLocationName(): String?
}

/**
 * Pure list helpers shared by all [LocationStorage] implementations.
 * Coordinates match when rounded to 2 decimals — same as the Flutter app.
 */
internal object LocationListOps {
    fun rounded(value: Double): String = "%.2f".format(java.util.Locale.US, value)

    fun sameArea(aLat: Double, aLng: Double, bLat: Double, bLng: Double): Boolean =
        rounded(aLat) == rounded(bLat) && rounded(aLng) == rounded(bLng)

    /** Replaces the same-area entry if present, otherwise appends. */
    fun upsert(list: List<SavedLocation>, value: SavedLocation): List<SavedLocation> {
        val index = list.indexOfFirst {
            sameArea(it.latitude, it.longitude, value.latitude, value.longitude)
        }
        return if (index >= 0) list.toMutableList().also { it[index] = value } else list + value
    }

    fun remove(list: List<SavedLocation>, latitude: Double, longitude: Double): List<SavedLocation> =
        list.filterNot { sameArea(it.latitude, it.longitude, latitude, longitude) }
}

/** In-memory [LocationStorage]; used in tests and previews. */
class InMemoryLocationStorage : LocationStorage {
    private var current: CurrentLocation? = null
    private var saved: List<SavedLocation> = emptyList()
    private var cachedName: String? = null

    override suspend fun saveCurrentLocation(value: CurrentLocation) { current = value }
    override suspend fun getCurrentLocation(): CurrentLocation? = current
    override suspend fun getSavedLocations(): List<SavedLocation> = saved
    override suspend fun saveLocation(value: SavedLocation) { saved = LocationListOps.upsert(saved, value) }
    override suspend fun deleteLocation(latitude: Double, longitude: Double) {
        saved = LocationListOps.remove(saved, latitude, longitude)
    }
    override suspend fun cacheLocationName(name: String) { cachedName = name }
    override suspend fun getCachedLocationName(): String? = cachedName
}

/** SharedPreferences-backed [LocationStorage]. Same key names as the Flutter app. */
class PrefsLocationStorage(context: Context) : LocationStorage {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    override suspend fun saveCurrentLocation(value: CurrentLocation) = withContext(Dispatchers.IO) {
        prefs.edit { putString(KEY_CURRENT, json.encodeToString(CurrentLocation.serializer(), value)) }
    }

    override suspend fun getCurrentLocation(): CurrentLocation? = withContext(Dispatchers.IO) {
        prefs.getString(KEY_CURRENT, null)?.let { runCatching { json.decodeFromString(CurrentLocation.serializer(), it) }.getOrNull() }
    }

    override suspend fun getSavedLocations(): List<SavedLocation> = withContext(Dispatchers.IO) {
        prefs.getString(KEY_SAVED, null)?.let {
            runCatching { json.decodeFromString(ListSerializer(SavedLocation.serializer()), it) }.getOrDefault(emptyList())
        } ?: emptyList()
    }

    override suspend fun saveLocation(value: SavedLocation) = withContext(Dispatchers.IO) {
        // Read-modify-write on the IO dispatcher; acceptable for a settings-rate flow.
        val current = prefs.getString(KEY_SAVED, null)?.let {
            runCatching { json.decodeFromString(ListSerializer(SavedLocation.serializer()), it) }.getOrDefault(emptyList())
        } ?: emptyList()
        val updated = LocationListOps.upsert(current, value)
        prefs.edit { putString(KEY_SAVED, json.encodeToString(ListSerializer(SavedLocation.serializer()), updated)) }
    }

    override suspend fun deleteLocation(latitude: Double, longitude: Double) = withContext(Dispatchers.IO) {
        val current = prefs.getString(KEY_SAVED, null)?.let {
            runCatching { json.decodeFromString(ListSerializer(SavedLocation.serializer()), it) }.getOrDefault(emptyList())
        } ?: emptyList()
        val updated = LocationListOps.remove(current, latitude, longitude)
        prefs.edit { putString(KEY_SAVED, json.encodeToString(ListSerializer(SavedLocation.serializer()), updated)) }
    }

    override suspend fun cacheLocationName(name: String) = withContext(Dispatchers.IO) {
        prefs.edit { putString(KEY_NAME, name) }
    }

    override suspend fun getCachedLocationName(): String? = withContext(Dispatchers.IO) {
        prefs.getString(KEY_NAME, null)
    }

    companion object {
        const val PREFS = "prayer_notifier_location"
        const val KEY_CURRENT = "current_location"
        const val KEY_SAVED = "saved_locations"
        const val KEY_NAME = "cached_location_name"
    }
}
