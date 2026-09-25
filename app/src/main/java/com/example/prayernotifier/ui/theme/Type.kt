package com.example.prayernotifier.ui.theme

import android.content.Context
import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.example.prayernotifier.R

//region Wonderous typography — each family has one job:
// Yeseva One for the hero name, Tenor Sans for titles, Raleway for body/UI.
//endregion

val YesevaOne = FontFamily(Font(R.font.yeseva_one))
val TenorSans = FontFamily(Font(R.font.tenor_sans))

// Raleway ships as a variable font; pin each weight through its axis.
@OptIn(ExperimentalTextApi::class)
private fun raleway(weight: FontWeight, style: FontStyle = FontStyle.Normal) = Font(
    resId = if (style == FontStyle.Italic) R.font.raleway_italic else R.font.raleway,
    weight = weight,
    style = style,
    variationSettings = FontVariation.Settings(FontVariation.weight(weight.weight))
)

val Raleway = FontFamily(
    raleway(FontWeight.Normal),
    raleway(FontWeight.Medium),
    raleway(FontWeight.SemiBold),
    raleway(FontWeight.Normal, FontStyle.Italic),
    raleway(FontWeight.Medium, FontStyle.Italic),
    raleway(FontWeight.SemiBold, FontStyle.Italic)
)

// Arabic has no glyphs in the Latin faces above; Amiri, a classical Naskh
// serif, carries the same museum-book voice. Fallback when Thmanyah is absent.
val Amiri = FontFamily(
    Font(R.font.amiri, FontWeight.Normal),
    Font(R.font.amiri_bold, FontWeight.Bold)
)

val AppTypography = Typography(
    // Wonder title: the next prayer's name over the arch.
    displayLarge = TextStyle(
        fontFamily = YesevaOne, fontSize = 64.sp, lineHeight = 56.sp
    ),
    // H1.
    displayMedium = TextStyle(
        fontFamily = TenorSans, fontSize = 64.sp, lineHeight = 62.sp
    ),
    // H2: countdown, section titles.
    displaySmall = TextStyle(
        fontFamily = TenorSans, fontSize = 32.sp, lineHeight = 46.sp
    ),
    // H3: prayer time in event cards, page titles.
    headlineMedium = TextStyle(
        fontFamily = TenorSans, fontSize = 24.sp, lineHeight = 36.sp
    ),
    headlineSmall = TextStyle(
        fontFamily = TenorSans, fontSize = 24.sp, lineHeight = 36.sp
    ),
    // Title 1: uppercase eyebrow ("THE ANCIENT WONDER").
    titleLarge = TextStyle(
        fontFamily = TenorSans, fontSize = 16.sp, lineHeight = 26.sp,
        letterSpacing = 0.05.em
    ),
    // Body bold.
    titleMedium = TextStyle(
        fontFamily = Raleway, fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp, lineHeight = 26.sp
    ),
    // Title 2: small Tenor titles, metadata labels (uppercase, tracked).
    titleSmall = TextStyle(
        fontFamily = TenorSans, fontSize = 14.sp, lineHeight = 16.sp,
        letterSpacing = 0.05.em
    ),
    // Body.
    bodyLarge = TextStyle(
        fontFamily = Raleway, fontSize = 16.sp, lineHeight = 26.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = Raleway, fontSize = 16.sp, lineHeight = 26.sp
    ),
    // Body small.
    bodySmall = TextStyle(
        fontFamily = Raleway, fontSize = 14.sp, lineHeight = 23.sp
    ),
    // Button: uppercase Raleway 14, +2%.
    labelLarge = TextStyle(
        fontFamily = Raleway, fontWeight = FontWeight.Medium,
        fontSize = 14.sp, lineHeight = 14.sp, letterSpacing = 0.02.em
    ),
    // H4: metadata labels.
    labelMedium = TextStyle(
        fontFamily = Raleway, fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp, lineHeight = 23.sp, letterSpacing = 0.05.em
    ),
    // Caption: italic credits and source lines.
    labelSmall = TextStyle(
        fontFamily = Raleway, fontWeight = FontWeight.Medium, fontStyle = FontStyle.Italic,
        fontSize = 14.sp, lineHeight = 20.sp
    )
)

/**
 * Arabic families: Thmanyah Serif Display for display and titles, Thmanyah
 * Sans for body and UI. The Thmanyah files are git-ignored (their license
 * forbids hosting them) and looked up by name; a checkout without them
 * falls back to Amiri and the system Arabic sans.
 */
private class ArabicFamilies(val display: FontFamily, val sans: FontFamily)

private val THMANYAH_FILES = listOf(
    "thmanyah_serif_display", "thmanyah_serif_display_bold",
    "thmanyah_sans", "thmanyah_sans_medium", "thmanyah_sans_bold"
)

/** True when this build bundles the optional Thmanyah fonts. */
fun thmanyahAvailable(context: Context): Boolean = THMANYAH_FILES.all {
    context.resources.getIdentifier(it, "font", context.packageName) != 0
}

private fun arabicFamilies(context: Context): ArabicFamilies {
    fun font(name: String): Int =
        context.resources.getIdentifier(name, "font", context.packageName)
    val display = font("thmanyah_serif_display")
    val displayBold = font("thmanyah_serif_display_bold")
    val sans = font("thmanyah_sans")
    val sansMedium = font("thmanyah_sans_medium")
    val sansBold = font("thmanyah_sans_bold")
    if (!thmanyahAvailable(context)) {
        return ArabicFamilies(Amiri, FontFamily.Default)
    }
    return ArabicFamilies(
        display = FontFamily(
            Font(display, FontWeight.Normal),
            Font(displayBold, FontWeight.Bold)
        ),
        sans = FontFamily(
            Font(sans, FontWeight.Normal),
            Font(sansMedium, FontWeight.Medium),
            // Thmanyah ships no SemiBold; Medium is the closer match for
            // body-bold text than Bold.
            Font(sansMedium, FontWeight.SemiBold),
            Font(sansBold, FontWeight.Bold)
        )
    )
}

/**
 * Arabic variant of [AppTypography]: display serif for the hero and titles
 * (Bold for the prayer name), sans for body, and no letter spacing, which
 * would break Arabic's joined letters.
 */
fun arabicTypography(context: Context): Typography {
    val families = arabicFamilies(context)
    fun TextStyle.arabic(family: FontFamily, weight: FontWeight? = null) = copy(
        fontFamily = family,
        fontWeight = weight ?: fontWeight,
        fontStyle = FontStyle.Normal,
        letterSpacing = 0.sp
    )
    return AppTypography.run {
        Typography(
            displayLarge = displayLarge.arabic(families.display, FontWeight.Bold)
                .copy(fontSize = 60.sp, lineHeight = 84.sp),
            displayMedium = displayMedium.arabic(families.display),
            displaySmall = displaySmall.arabic(families.display),
            headlineMedium = headlineMedium.arabic(families.display),
            headlineSmall = headlineSmall.arabic(families.display),
            titleLarge = titleLarge.arabic(families.display),
            titleMedium = titleMedium.arabic(families.sans),
            titleSmall = titleSmall.arabic(families.sans, FontWeight.Medium),
            bodyLarge = bodyLarge.arabic(families.sans),
            bodyMedium = bodyMedium.arabic(families.sans),
            bodySmall = bodySmall.arabic(families.sans),
            labelLarge = labelLarge.arabic(families.sans),
            labelMedium = labelMedium.arabic(families.sans),
            labelSmall = labelSmall.arabic(families.sans)
        )
    }
}
