package com.example.prayernotifier.data.persistence

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [PrayerDayEntity::class], version = 1, exportSchema = false)
abstract class PrayerDatabase : RoomDatabase() {
    abstract fun prayerDayDao(): PrayerDayDao
}

fun prayerDatabase(context: Context): PrayerDatabase =
    Room.databaseBuilder(
        context.applicationContext,
        PrayerDatabase::class.java,
        "prayer.db"
    ).build()
