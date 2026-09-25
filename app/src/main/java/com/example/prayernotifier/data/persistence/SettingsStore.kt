package com.example.prayernotifier.data.persistence

import kotlinx.serialization.json.Json

/** Persists [AppSettings] as JSON. Missing or corrupt data → defaults. */
class SettingsStore(private val store: KeyValueStore) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun load(): AppSettings {
        val raw = store.get(KEY) ?: return AppSettings()
        return runCatching { json.decodeFromString(AppSettings.serializer(), raw) }
            .getOrDefault(AppSettings())
    }

    suspend fun save(settings: AppSettings) {
        store.put(KEY, json.encodeToString(AppSettings.serializer(), settings))
    }

    companion object {
        const val KEY = "app_settings"
    }
}
