package com.example.prayernotifier.data.persistence

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [PrayerDayEntity::class], version = 1, exportSchema = false)
abstract class PrayerDatabase : RoomDatabase() {
    abstract fun prayerDayDao(): PrayerDayDao
}

@Volatile
private var instance: PrayerDatabase? = null

/**
 * The one database for the whole process (screens, alarm receiver, offline
 * downloads). Room expects a single instance per file; separate ones would
 * each keep their own connections and could see each other's writes late.
 */
fun prayerDatabase(context: Context): PrayerDatabase =
    instance ?: synchronized(PrayerDatabase::class) {
        instance ?: Room.databaseBuilder(
            context.applicationContext,
            PrayerDatabase::class.java,
            "prayer.db"
        ).build().also { instance = it }
    }
