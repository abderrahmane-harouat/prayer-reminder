package com.example.athan_app_v2

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Skill: jetpack-compose-ui — draw behind the status bar instead of
        // Android painting a gray bar there. Must run before content is set.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
