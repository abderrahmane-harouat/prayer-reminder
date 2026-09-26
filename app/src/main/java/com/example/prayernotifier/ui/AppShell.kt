package com.example.prayernotifier.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.EaseOutCubic
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.zIndex
import com.example.prayernotifier.ui.home.HomeScreen
import com.example.prayernotifier.ui.settings.SettingsScreen

/** Wonderous "fast" duration; motion arrives quickly and settles softly. */
private const val PAGE_TRANSITION_MS = 300

/**
 * Home is the root, Settings is a pushed page reached
 * from the top-left floating circle and closed with its back circle or the
 * system back gesture. Both stay composed (IndexedStack equivalent),
 * preserving scroll and field state across switches.
 *
 * The switch animates like Wonderous pages: Settings fades in while sliding
 * from the end edge, and Home fades out with a small parallax shift the
 * other way. Mirrored in RTL. One progress value drives both pages so they
 * can never disagree mid-transition.
 */
@Composable
fun AppShell() {
    var showSettings by rememberSaveable { mutableStateOf(false) }

    BackHandler(enabled = showSettings) { showSettings = false }

    // 0 = Home, 1 = Settings. Honors the system "remove animations" setting.
    val progress by animateFloatAsState(
        targetValue = if (showSettings) 1f else 0f,
        animationSpec = tween(PAGE_TRANSITION_MS, easing = EaseOutCubic),
        label = "page"
    )
    // +1 slides toward the end edge: right in LTR, left in RTL.
    val direction = if (LocalLayoutDirection.current == LayoutDirection.Ltr) 1f else -1f

    // Page color first, then safeDrawing (skill rule): the status and nav bar
    // areas take the warm-black page color on both pages.
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .windowInsetsPadding(WindowInsets.safeDrawing)
    ) {
        PageLayer(
            interactive = !showSettings,
            // Home stays underneath; Settings takes the top while any of it shows.
            z = 0.5f,
            modifier = Modifier.graphicsLayer {
                alpha = 1f - progress
                translationX = -direction * size.width * 0.12f * progress
            }
        ) {
            HomeScreen(visible = !showSettings, onOpenSettings = { showSettings = true })
        }
        PageLayer(
            interactive = showSettings,
            z = if (progress > 0f) 1f else 0f,
            modifier = Modifier.graphicsLayer {
                alpha = progress
                translationX = direction * size.width * 0.25f * (1f - progress)
            }
        ) {
            SettingsScreen(visible = showSettings, onBack = { showSettings = false })
        }
    }
}

/**
 * Keeps a page composed when hidden so its state survives switches. While
 * not [interactive] (hidden, or animating out) a touch shield swallows taps.
 */
@Composable
private fun PageLayer(
    interactive: Boolean,
    z: Float,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .zIndex(z)
    ) {
        content()
        if (!interactive) {
            // Opaque touch shield ABOVE the hidden content: without it, taps
            // fall through the visible page's empty areas and trigger the
            // hidden page's rows. Must be declared after content() to win hits.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        onClick = {}
                    )
            )
        }
    }
}
