package com.example.prayernotifier.data.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.Priority
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/**
 * [PositionProvider] backed by the Fused Location Provider.
 *
 * Note: this provider only *checks* permissions — requesting them needs an
 * Activity, so that stays in the UI layer. The UI should request
 * [Manifest.permission.ACCESS_FINE_LOCATION] (or COARSE) on
 * [LocationException.PermissionDenied] and call [LocationService.refreshLocation] again.
 */
class FusedPositionProvider(context: Context) : PositionProvider {
    private val app = context.applicationContext
    private val client = LocationServices.getFusedLocationProviderClient(app)

    override suspend fun currentFix(): PositionOutcome = withContext(Dispatchers.IO) {
        // Permission first: on a first run the user must see the permission
        // dialog before anything else, even when location is switched off.
        val fine = ContextCompat.checkSelfPermission(app, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(app, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        if (!fine && !coarse) return@withContext PositionOutcome.PermissionMissing

        val manager = app.getSystemService(LocationManager::class.java)
            ?: return@withContext PositionOutcome.ServiceDisabled
        val enabled = try {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } catch (e: SecurityException) {
            return@withContext PositionOutcome.PermissionMissing
        } catch (e: IllegalArgumentException) {
            false
        }
        if (!enabled) return@withContext PositionOutcome.ServiceDisabled

        // High accuracy engages GPS, which answers in seconds where the
        // balanced (network) provider can stall until the timeout. A fix up
        // to a minute old is reused instantly.
        val request = CurrentLocationRequest.Builder()
            .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
            .setMaxUpdateAgeMillis(60_000)
            .setDurationMillis(FIX_TIMEOUT_MS)
            .build()
        val location = try {
            withTimeoutOrNull(FIX_TIMEOUT_MS) {
                client.getCurrentLocation(request, null).await()
            }
        } catch (e: SecurityException) {
            return@withContext PositionOutcome.PermissionMissing
        } catch (e: Exception) {
            null
        } ?: try {
            // Fallback: a fresh fix is not always available (indoor, emulator)
            // — a recent last-known location is good enough for prayer times.
            client.lastLocation.await()
        } catch (e: SecurityException) {
            return@withContext PositionOutcome.PermissionMissing
        } catch (e: Exception) {
            null
        } ?: return@withContext PositionOutcome.NoFix

        PositionOutcome.Fix(LatLng(location.latitude, location.longitude))
    }

    private companion object {
        const val FIX_TIMEOUT_MS = 10_000L
    }
}
