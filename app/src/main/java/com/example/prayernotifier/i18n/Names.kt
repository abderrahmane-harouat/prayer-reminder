package com.example.prayernotifier.i18n

import androidx.annotation.StringRes
import com.example.prayernotifier.R
import java.text.Normalizer

/** Display-name resource for a prayer id ("Fajr" … "Isha"). */
@StringRes
fun prayerNameRes(prayer: String): Int = when (prayer) {
    "Fajr" -> R.string.prayer_fajr
    "Dhuhr" -> R.string.prayer_dhuhr
    "Asr" -> R.string.prayer_asr
    "Maghrib" -> R.string.prayer_maghrib
    else -> R.string.prayer_isha
}

// Aladhan's English month names ("Rabīʿ al-thānī"), reduced to plain a–z.
private val HIJRI_KEYS = listOf(
    "muharram", "safar", "rabialawwal", "rabialthani", "jumadaalula", "jumadaalakhirah",
    "rajab", "shaban", "ramadan", "shawwal", "dhualqadah", "dhualhijjah"
)

/**
 * Index (0 = Muharram) of the Hijri month named by the API's English
 * transliteration, or -1 when unknown. Accents and ʿ marks are ignored, so
 * small spelling changes upstream don't break the lookup.
 */
fun hijriMonthIndex(monthEn: String): Int {
    val key = Normalizer.normalize(monthEn, Normalizer.Form.NFD)
        .lowercase()
        .filter { it in 'a'..'z' }
    return HIJRI_KEYS.indexOf(key)
}
