package com.example.prayernotifier.data.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Receives exact-alarm fires, the daily re-plan alarm, and reboots. */
class PrayerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                val handler = AppGraph(context).handler
                when (intent.action) {
                    ExactAlarmScheduler.ACTION_PRAYER_ALARM -> handler.onAlarmFired(
                        intent.getStringExtra(ExactAlarmScheduler.EXTRA_PRAYER).orEmpty(),
                        intent.getStringExtra(ExactAlarmScheduler.EXTRA_TIME).orEmpty()
                    )
                    ExactAlarmScheduler.ACTION_REPLENISH,
                    Intent.ACTION_BOOT_COMPLETED -> handler.onDayChanged()
                }
            } finally {
                pending.finish()
            }
        }
    }
}
