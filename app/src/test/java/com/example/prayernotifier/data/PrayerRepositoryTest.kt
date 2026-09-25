package com.example.prayernotifier.data

import kotlinx.coroutines.test.runTest
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class PrayerRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: PrayerRepository

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        repository = PrayerRepository(AladhanApi.create(server.url("/").toString()))
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun `maps calendar response stripping timezone suffix`() = runTest {
        server.enqueue(MockResponse().setBody(SAMPLE_RESPONSE).setResponseCode(200))

        val days = repository.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)

        assertEquals(2, days.size)
        val first = days[0]
        assertEquals("05:12", first.timings.fajr)
        assertEquals("12:45", first.timings.dhuhr)
        assertEquals("16:10", first.timings.asr)
        assertEquals("18:52", first.timings.maghrib)
        assertEquals("20:20", first.timings.isha)
        assertEquals("01 Sep 2026", first.readableDate)
        assertEquals("09", first.hijri.day)
        assertEquals("1448", first.hijri.year)
        assertTrue(first.hijri.monthEn.isNotBlank())

        val request = server.takeRequest()
        assertTrue(request.path!!.startsWith("/v1/calendar/2026/9"))
        assertTrue(request.path!!.contains("latitude=21.4225"))
        assertTrue(request.path!!.contains("longitude=39.8262"))
    }

    @Test(expected = IllegalStateException::class)
    fun `throws on non-200 api code`() = runTest {
        server.enqueue(MockResponse().setBody("""{"code":400,"status":"BAD","data":[]}"""))
        repository.getPrayerTimesForMonth(2026, 9, 21.4225, 39.8262)
    }

    companion object {
        private const val SAMPLE_RESPONSE = """
        {
          "code": 200, "status": "OK",
          "data": [
            {
              "timings": {
                "Fajr": "05:12 (EET)", "Sunrise": "06:40 (EET)",
                "Dhuhr": "12:45 (EET)", "Asr": "16:10 (EET)",
                "Maghrib": "18:52 (EET)", "Isha": "20:20 (EET)",
                "Imsak": "05:02 (EET)", "Midnight": "00:45 (EET)"
              },
              "date": {
                "readable": "01 Sep 2026",
                "hijri": {
                  "date": "09-03-1448", "day": "09", "year": "1448",
                  "month": {"en": "Rabīʿ al-awwal"}
                }
              }
            },
            {
              "timings": {
                "Fajr": "05:13 (+03)", "Sunrise": "06:41 (+03)",
                "Dhuhr": "12:45 (+03)", "Asr": "16:09 (+03)",
                "Maghrib": "18:51 (+03)", "Isha": "20:19 (+03)",
                "Imsak": "05:03 (+03)", "Midnight": "00:45 (+03)"
              },
              "date": {
                "readable": "02 Sep 2026",
                "hijri": {
                  "date": "10-03-1448", "day": "10", "year": "1448",
                  "month": {"en": "Rabīʿ al-awwal"}
                }
              }
            }
          ]
        }
        """
    }
}
