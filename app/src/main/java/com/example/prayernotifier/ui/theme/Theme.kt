package com.example.prayernotifier.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.core.os.ConfigurationCompat

// Wonderous is dark-only: warm black page, #272625 cards, parchment text.
// Material slots are mapped so stock widgets (Switch, Slider, DatePicker)
// pick up the orange accent and warm neutrals.
private val WonderColors = darkColorScheme(
    primary = WonderAccent1,
    onPrimary = WonderWhite,
    primaryContainer = WonderAccent3,
    onPrimaryContainer = WonderWhite,
    secondary = WonderAccent2,
    onSecondary = WonderBlack,
    background = WonderBlack,
    onBackground = WonderOffWhite,
    surface = WonderBlack,
    onSurface = WonderOffWhite,
    surfaceVariant = WonderGreyStrong,
    onSurfaceVariant = WonderAccent2,
    surfaceContainerLowest = WonderBlack,
    surfaceContainerLow = WonderGreyStrong,
    surfaceContainer = WonderGreyStrong,
    surfaceContainerHigh = WonderGreyStrong,
    surfaceContainerHighest = WonderGreyStrong,
    outline = WonderGreyMedium,
    outlineVariant = WonderCaption.copy(alpha = 0.5f),
    inverseSurface = WonderOffWhite,
    inverseOnSurface = WonderBlack,
    inversePrimary = WonderAccent3,
    error = WonderAccent1,
    onError = WonderWhite,
    scrim = WonderBlack
)

private val WonderShapes = Shapes(
    extraSmall = RoundedCornerShape(WonderCorners.small),
    small = RoundedCornerShape(WonderCorners.card),
    medium = RoundedCornerShape(WonderCorners.card),
    large = RoundedCornerShape(WonderCorners.panel),
    extraLarge = RoundedCornerShape(WonderCorners.panel)
)

@Composable
fun PrayerNotifierTheme(content: @Composable () -> Unit) {
    val language = ConfigurationCompat.getLocales(LocalConfiguration.current)[0]?.language
    val context = LocalContext.current
    val typography = remember(language, context) {
        if (language == "ar") arabicTypography(context) else AppTypography
    }
    MaterialTheme(
        colorScheme = WonderColors,
        typography = typography,
        shapes = WonderShapes,
        content = content
    )
}
