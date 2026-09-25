package com.example.prayernotifier.i18n

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import java.util.Locale

/**
 * The app's language choice, on top of AndroidX per-app locales.
 *
 * Android 13+ owns the choice: it is stored by the system and editable from
 * Settings → Apps → Language, so we only read and write it. Android 12 and
 * lower have no system store, so we keep the tag in our own prefs and
 * re-apply it on launch (the "custom storage" path in the AndroidX docs).
 * The prefs copy also lets background work (alarm notifications, which run
 * without an Activity) render text in the chosen language there.
 */
object AppLanguage {
    /** Empty tag = follow the system language. */
    const val SYSTEM = ""
    const val ENGLISH = "en"
    const val ARABIC = "ar"

    private const val PREFS = "app_language"
    private const val KEY_TAG = "tag"

    /** Current choice as a language tag, or [SYSTEM]. */
    fun current(context: Context): String =
        if (Build.VERSION.SDK_INT >= 33) {
            AppCompatDelegate.getApplicationLocales().get(0)?.language ?: SYSTEM
        } else {
            savedTag(context)
        }

    /** Applies [tag] app-wide; the visible Activity is recreated in it. */
    fun set(context: Context, tag: String) {
        prefs(context).edit().putString(KEY_TAG, tag).apply()
        AppCompatDelegate.setApplicationLocales(
            if (tag == SYSTEM) {
                LocaleListCompat.getEmptyLocaleList()
            } else {
                LocaleListCompat.forLanguageTags(tag)
            }
        )
    }

    /**
     * Re-applies the saved choice on Android 12 and lower, where AppCompat
     * forgets it when the process dies. Call from Activity.onCreate before
     * super.onCreate. No-op on 13+ (the system restores it).
     */
    fun restore(context: Context) {
        if (Build.VERSION.SDK_INT >= 33) return
        val tag = savedTag(context)
        if (tag != SYSTEM && AppCompatDelegate.getApplicationLocales().isEmpty) {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))
        }
    }

    /**
     * A context whose resources speak the chosen language, for code that
     * runs without an Activity. On 13+ the system already applies the app
     * locale to the application context.
     */
    fun localizedContext(context: Context): Context {
        if (Build.VERSION.SDK_INT >= 33) return context
        val tag = savedTag(context)
        if (tag == SYSTEM) return context
        val config = Configuration(context.resources.configuration)
        config.setLocale(Locale.forLanguageTag(tag))
        return context.createConfigurationContext(config)
    }

    private fun savedTag(context: Context): String =
        prefs(context).getString(KEY_TAG, SYSTEM) ?: SYSTEM

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
