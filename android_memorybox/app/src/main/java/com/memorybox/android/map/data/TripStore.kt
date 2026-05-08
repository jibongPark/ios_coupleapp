package com.memorybox.android.map.data

import android.content.Context
import com.memorybox.android.map.domain.Trip
import java.io.File
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

class TripStore(private val storageFile: File) {
    private val json = Json {
        ignoreUnknownKeys = true
        prettyPrint = true
    }

    fun loadAll(): Map<Int, Trip> {
        if (!storageFile.exists() || storageFile.length() == 0L) return emptyMap()

        return runCatching {
            json.decodeFromString(ListSerializer(Trip.serializer()), storageFile.readText())
                .associateBy { it.sigunguCode }
        }.getOrElse {
            quarantineCorruptFile()
            emptyMap()
        }
    }

    fun load(sigunguCode: Int): Trip? = loadAll()[sigunguCode]

    fun upsert(trip: Trip) {
        val trips = loadAll().toMutableMap()
        trips[trip.sigunguCode] = trip
        saveAll(trips.values)
    }

    fun delete(sigunguCode: Int): Trip? {
        val trips = loadAll().toMutableMap()
        val deleted = trips.remove(sigunguCode) ?: return null
        saveAll(trips.values)
        return deleted
    }

    private fun saveAll(trips: Collection<Trip>) {
        storageFile.parentFile?.mkdirs()
        val orderedTrips = trips.sortedBy { it.sigunguCode }
        storageFile.writeText(json.encodeToString(ListSerializer(Trip.serializer()), orderedTrips))
    }

    private fun quarantineCorruptFile() {
        val parent = storageFile.parentFile ?: return
        if (!storageFile.exists()) return

        runCatching {
            val quarantine = File(parent, "${storageFile.name}.corrupt-${System.currentTimeMillis()}")
            storageFile.copyTo(quarantine, overwrite = true)
            storageFile.delete()
        }
    }

    companion object {
        private const val FILE_NAME = "map_trips.json"

        fun appPrivate(context: Context): TripStore = TripStore(File(context.filesDir, FILE_NAME))
    }
}
