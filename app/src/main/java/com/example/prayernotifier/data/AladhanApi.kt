package com.example.prayernotifier.data

import retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query
import java.util.concurrent.TimeUnit

//region Wire DTOs (api.aladhan.com/v1/calendar)

@Serializable
data class CalendarResponse(
    val code: Int,
    val status: String,
    val data: List<PrayerDayDto>
)

@Serializable
data class PrayerDayDto(
    val timings: Map<String, String>,
    val date: DateDto
)

@Serializable
data class DateDto(
    val readable: String,
    val hijri: HijriDto
)

@Serializable
data class HijriDto(
    val date: String,
    val day: String,
    val year: String,
    val month: HijriMonthDto
)

@Serializable
data class HijriMonthDto(
    @SerialName("en") val en: String
)

//endregion

/** Aladhan calendar API — same endpoint/params as the Flutter `PrayerService`. */
interface AladhanApi {
    @GET("v1/calendar/{year}/{month}")
    suspend fun getCalendar(
        @Path("year") year: Int,
        @Path("month") month: Int,
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double
    ): CalendarResponse

    companion object {
        const val BASE_URL = "https://api.aladhan.com/"

        fun create(baseUrl: String = BASE_URL): AladhanApi {
            val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }
            val client = OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build()
            return Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(client)
                .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
                .build()
                .create(AladhanApi::class.java)
        }
    }
}

/** Maps wire DTOs to domain models. Strips the " (EET)" suffix like Flutter. */
class PrayerRepository(private val api: AladhanApi) {

    suspend fun getPrayerTimesForMonth(
        year: Int,
        month: Int,
        latitude: Double,
        longitude: Double
    ): List<PrayerDay> {
        val response = api.getCalendar(year, month, latitude, longitude)
        if (response.code != 200) throw IllegalStateException("Aladhan error: ${response.status}")
        return response.data.map { it.toDomain() }
    }

    private fun PrayerDayDto.toDomain() = PrayerDay(
        timings = PrayerTimings(
            fajr = timeOf("Fajr"),
            dhuhr = timeOf("Dhuhr"),
            asr = timeOf("Asr"),
            maghrib = timeOf("Maghrib"),
            isha = timeOf("Isha")
        ),
        hijri = HijriDate(
            date = date.hijri.date,
            day = date.hijri.day,
            monthEn = date.hijri.month.en,
            year = date.hijri.year
        ),
        readableDate = date.readable
    )

    private fun PrayerDayDto.timeOf(key: String): String =
        (timings[key] ?: error("Missing timing: $key")).substringBefore(' ')
}
