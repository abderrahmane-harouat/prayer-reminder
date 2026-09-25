package com.example.prayernotifier.data.connectivity

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** What the phone is connected through; [None] means no usable internet. */
enum class NetworkKind { None, Wifi, Cellular, Ethernet, Other }

/** One synchronous "are we online right now, and how" check. */
interface NetworkProbe {
    fun isOnline(): Boolean
    fun kind(): NetworkKind = if (isOnline()) NetworkKind.Other else NetworkKind.None
}

/**
 * [NetworkProbe] backed by Android's [ConnectivityManager]. Online means the
 * default network offers internet and is not stuck behind a captive portal
 * (hotel/airport login page) - whatever carries it: Wi-Fi, mobile data,
 * Ethernet, or a VPN on top of any of those.
 */
class SystemNetworkProbe(context: Context) : NetworkProbe {
    private val manager = context.applicationContext.getSystemService(ConnectivityManager::class.java)

    override fun kind(): NetworkKind {
        val caps = manager?.getNetworkCapabilities(manager.activeNetwork) ?: return NetworkKind.None
        if (!caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) ||
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL)
        ) {
            return NetworkKind.None
        }
        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> NetworkKind.Wifi
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> NetworkKind.Cellular
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> NetworkKind.Ethernet
            // VPN, USB/Bluetooth tethering, ...
            else -> NetworkKind.Other
        }
    }

    override fun isOnline(): Boolean = kind() != NetworkKind.None
}

/**
 * Holds the current online status and re-checks on demand.
 * Mirrors the Flutter `ConnectivityService` (`isOnline` + change stream).
 */
interface ConnectivityMonitor {
    val isOnline: StateFlow<Boolean>
    val kind: StateFlow<NetworkKind>
    fun refresh(): Boolean
}

class DefaultConnectivityMonitor(probe: NetworkProbe) : ConnectivityMonitor {
    private val current = probe
    private val _kind = MutableStateFlow(current.kind())
    private val _isOnline = MutableStateFlow(_kind.value != NetworkKind.None)
    override val isOnline: StateFlow<Boolean> = _isOnline.asStateFlow()
    override val kind: StateFlow<NetworkKind> = _kind.asStateFlow()

    override fun refresh(): Boolean {
        val now = current.kind()
        _kind.value = now
        _isOnline.value = now != NetworkKind.None
        return _isOnline.value
    }
}

/**
 * Android glue: re-probes whenever the system reports a network change.
 * Returns the callback so the caller can unregister it when done.
 */
fun ConnectivityMonitor.observeSystemNetworks(
    context: Context,
    scope: CoroutineScope
): ConnectivityManager.NetworkCallback {
    val manager = context.applicationContext.getSystemService(ConnectivityManager::class.java)
    val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: android.net.Network) {
            scope.launch { refresh() }
        }

        override fun onLost(network: android.net.Network) {
            scope.launch { refresh() }
        }

        override fun onCapabilitiesChanged(
            network: android.net.Network,
            capabilities: NetworkCapabilities
        ) {
            scope.launch { refresh() }
        }
    }
    manager.registerDefaultNetworkCallback(callback)
    return callback
}

/**
 * Real end-to-end check: can we reach the prayer-times server right now,
 * over whatever network is active (Wi-Fi, mobile data, VPN)? Any HTTP
 * answer counts as reachable; only network failures count as down.
 */
suspend fun canReachPrayerServer(url: String = "https://api.aladhan.com/"): Boolean =
    withContext(Dispatchers.IO) {
        try {
            val connection = URL(url).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "HEAD"
                connection.connectTimeout = 5_000
                connection.readTimeout = 5_000
                connection.responseCode
                true
            } finally {
                connection.disconnect()
            }
        } catch (e: IOException) {
            false
        }
    }
