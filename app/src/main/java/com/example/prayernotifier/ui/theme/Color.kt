package com.example.prayernotifier.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

//region Wonderous palette — a museum book: warm near-black, parchment, one
// orange accent. STYLE.md: chrome stays in these neutrals; color arrives only
// through illustration (see PrayerPalette).
//endregion

val WonderBlack = Color(0xFF1E1B18)       // page background, never pure black
val WonderGreyStrong = Color(0xFF272625)  // dark cards, sheets' raised surfaces
val WonderOffWhite = Color(0xFFF8ECE5)    // light text on dark, parchment
val WonderWhite = Color(0xFFFFFFFF)
val WonderBody = Color(0xFF514F4D)        // body text on parchment
val WonderCaption = Color(0xFF7D7873)     // captions, secondary text
val WonderGreyMedium = Color(0xFF9D9995)  // dividers, inactive icons
val WonderAccent1 = Color(0xFFE4935D)     // active state, links, "do it"
val WonderAccent2 = Color(0xFFBEABA1)     // metadata labels, muted text
val WonderAccent3 = Color(0xFFC47642)     // pressed / emphasis

/**
 * Per-prayer illustration palette, the equivalent of Wonderous' per-wonder
 * bg/fg pairs. Used only inside the arch illustration, never for chrome.
 */
data class PrayerPalette(
    val sky: Color,
    val land: Color,
    val landDeep: Color,
    val orb: Color,
    val night: Boolean
)

private val SunGold = Color(0xFFF6B94A)
private val MoonCream = WonderOffWhite

val PRAYER_PALETTES: Map<String, PrayerPalette> = mapOf(
    // Petra: pre-dawn indigo.
    "Fajr" to PrayerPalette(Color(0xFF444B9B), Color(0xFF2B2E7A), Color(0xFF1B1A65), MoonCream, night = true),
    // Machu Picchu: high noon sky.
    "Dhuhr" to PrayerPalette(Color(0xFF0E4064), Color(0xFFC1D9D1), Color(0xFF8FB3A8), SunGold, night = false),
    // Chichen Itza: long golden afternoon.
    "Asr" to PrayerPalette(Color(0xFF164F2A), Color(0xFFE2CFBB), Color(0xFFC9AE92), SunGold, night = false),
    // Taj Mahal: sunset coral.
    "Maghrib" to PrayerPalette(Color(0xFFC96454), Color(0xFF8A3A34), Color(0xFF642828), MoonCream, night = true),
    // Pyramids of Giza: deep night.
    "Isha" to PrayerPalette(Color(0xFF16184D), Color(0xFF444B9B), Color(0xFF2B2E7A), MoonCream, night = true)
)

fun paletteFor(prayer: String?): PrayerPalette =
    PRAYER_PALETTES[prayer] ?: PRAYER_PALETTES.getValue("Isha")

// Insets scale: 4, 8, 16, 24, 32, 48, 56 (+80 offset). 16 and 24 dominate.
object WonderSpacing {
    val x4 = 4.dp
    val x8 = 8.dp
    val x12 = 12.dp
    val x16 = 16.dp
    val x24 = 24.dp
    val x32 = 32.dp
    val x48 = 48.dp
    val x56 = 56.dp
}

// Radii: 4 small, 8 default (buttons, cards), 32 large panels / sheets.
object WonderCorners {
    val small = 4.dp
    val card = 8.dp
    val panel = 32.dp
}
