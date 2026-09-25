package com.example.prayernotifier.i18n

import org.junit.Assert.assertEquals
import org.junit.Test

class NamesTest {
    @Test
    fun `maps every Aladhan month spelling to its index`() {
        val aladhan = listOf(
            "Muḥarram", "Ṣafar", "Rabīʿ al-awwal", "Rabīʿ al-thānī", "Jumādá al-ūlá",
            "Jumādá al-ākhirah", "Rajab", "Shaʿbān", "Ramaḍān", "Shawwāl",
            "Dhū al-Qaʿdah", "Dhū al-Ḥijjah"
        )
        aladhan.forEachIndexed { index, name -> assertEquals(name, index, hijriMonthIndex(name)) }
    }

    @Test
    fun `ignores accents and case`() {
        assertEquals(8, hijriMonthIndex("RAMADAN"))
        assertEquals(4, hijriMonthIndex("Jumādā al-ūlā"))
    }

    @Test
    fun `unknown month returns -1`() {
        assertEquals(-1, hijriMonthIndex("Smarch"))
    }
}
