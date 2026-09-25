package com.example.prayernotifier

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.view.ViewTreeObserver
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.example.prayernotifier.data.UiGraphProvider
import com.example.prayernotifier.i18n.AppLanguage
import com.example.prayernotifier.ui.AppShell
import com.example.prayernotifier.ui.theme.PrayerNotifierTheme

// AppCompatActivity: required for AndroidX per-app languages to apply
// (and recreate the screen) on every Android version.
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        AppLanguage.restore(this)
        super.onCreate(savedInstanceState)
        // Skill: jetpack-compose-ui — draw behind the status bar instead of
        // Android painting a gray bar there. Runs before setContent.
        // The Wonderous theme is dark in every system mode, so the system
        // icons are always light.
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(Color.TRANSPARENT)
        )
        // Our warm-black pages already guarantee icon contrast,
        // so the API 35+ auto scrim would only paint over the design.
        if (Build.VERSION.SDK_INT >= 35) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= 31 && savedInstanceState == null) {
            holdSplashForAnimation()
        }
        setContent {
            PrayerNotifierTheme {
                UiGraphProvider {
                    // safeDrawing padding lives on AppShell's root, under the
                    // page color, so gray pages reach behind the system bars.
                    Surface(modifier = Modifier.fillMaxSize()) {
                        AppShell()
                    }
                }
            }
        }
    }

    /**
     * The app draws its first frame in ~300ms, which would cut the splash
     * icon animation (drawable/avd_splash.xml, 1000ms) short. Hold the first
     * draw until it has played once. Fresh launches only.
     */
    private fun holdSplashForAnimation() {
        val start = SystemClock.uptimeMillis()
        val content = findViewById<View>(android.R.id.content)
        content.viewTreeObserver.addOnPreDrawListener(
            object : ViewTreeObserver.OnPreDrawListener {
                override fun onPreDraw(): Boolean {
                    if (SystemClock.uptimeMillis() - start < SPLASH_ANIMATION_MS) return false
                    content.viewTreeObserver.removeOnPreDrawListener(this)
                    return true
                }
            }
        )
    }

    private companion object {
        const val SPLASH_ANIMATION_MS = 1000L
    }
}
