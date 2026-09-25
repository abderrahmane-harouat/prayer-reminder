package com.example.prayernotifier.data.persistence

import android.content.Context
import androidx.core.content.edit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Tiny string key-value abstraction.
 * Production uses SharedPreferences (local only — cloud backup is disabled
 * in the manifest); tests use the in-memory fake. An encrypted implementation
 * can be slotted in later without touching callers.
 */
interface KeyValueStore {
    suspend fun get(key: String): String?
    suspend fun put(key: String, value: String)
    suspend fun remove(key: String)
    suspend fun keys(): Set<String>
}

class InMemoryKeyValueStore : KeyValueStore {
    private val map = mutableMapOf<String, String>()
    override suspend fun get(key: String): String? = map[key]
    override suspend fun put(key: String, value: String) { map[key] = value }
    override suspend fun remove(key: String) { map.remove(key) }
    override suspend fun keys(): Set<String> = map.keys.toSet()
}

class PrefsKeyValueStore(context: Context, name: String) : KeyValueStore {
    private val prefs = context.applicationContext.getSharedPreferences(name, Context.MODE_PRIVATE)

    override suspend fun get(key: String): String? = withContext(Dispatchers.IO) {
        prefs.getString(key, null)
    }

    override suspend fun put(key: String, value: String) = withContext(Dispatchers.IO) {
        prefs.edit { putString(key, value) }
    }

    override suspend fun remove(key: String) = withContext(Dispatchers.IO) {
        prefs.edit { remove(key) }
    }

    override suspend fun keys(): Set<String> = withContext(Dispatchers.IO) {
        prefs.all.keys.toSet()
    }
}
