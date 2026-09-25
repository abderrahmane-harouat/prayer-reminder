package com.example.prayernotifier.data.connectivity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ConnectivityMonitorTest {

    @Test
    fun `starts with current probe value`() {
        assertTrue(DefaultConnectivityMonitor(FakeProbe(true)).isOnline.value)
        assertFalse(DefaultConnectivityMonitor(FakeProbe(false)).isOnline.value)
    }

    @Test
    fun `refresh picks up change and returns it`() {
        val probe = FakeProbe(true)
        val monitor = DefaultConnectivityMonitor(probe)

        probe.online = false
        assertFalse(monitor.refresh())
        assertFalse(monitor.isOnline.value)

        probe.online = true
        assertTrue(monitor.refresh())
        assertTrue(monitor.isOnline.value)
    }

    @Test
    fun `refresh with no change keeps value`() {
        val monitor = DefaultConnectivityMonitor(FakeProbe(true))
        assertTrue(monitor.refresh())
        assertTrue(monitor.isOnline.value)
    }

    @Test
    fun `kind follows the probe, mobile data counts as online`() {
        val probe = KindProbe(NetworkKind.Cellular)
        val monitor = DefaultConnectivityMonitor(probe)
        assertEquals(NetworkKind.Cellular, monitor.kind.value)
        assertTrue(monitor.isOnline.value)

        probe.current = NetworkKind.None
        assertFalse(monitor.refresh())
        assertEquals(NetworkKind.None, monitor.kind.value)

        probe.current = NetworkKind.Other // e.g. a VPN
        assertTrue(monitor.refresh())
    }

    private class KindProbe(var current: NetworkKind) : NetworkProbe {
        override fun isOnline() = current != NetworkKind.None
        override fun kind() = current
    }

    private class FakeProbe(var online: Boolean) : NetworkProbe {
        override fun isOnline(): Boolean = online
    }
}
