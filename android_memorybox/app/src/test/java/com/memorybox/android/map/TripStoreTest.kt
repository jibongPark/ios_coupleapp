package com.memorybox.android.map

import com.memorybox.android.map.data.TripStore
import com.memorybox.android.map.domain.Trip
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class TripStoreTest {
    @get:Rule
    val temporaryFolder = TemporaryFolder()

    @Test
    fun upsertPersistsTripsBySigunguCode() {
        val file = temporaryFolder.newFile("trips.json")
        val store = TripStore(file)
        val original = Trip(
            sigunguCode = 11110,
            images = listOf("trip-old.jpg"),
            startDateIso = "2026-04-01",
            endDateIso = "2026-04-03",
            memo = "first memo",
            scale = 1.25f,
            centerX = 0.2f,
            centerY = 0.4f,
        )
        val updated = original.copy(
            images = listOf("trip-new-1.jpg", "trip-new-2.jpg"),
            memo = "updated memo",
            scale = 1.75f,
        )

        store.upsert(original)
        store.upsert(updated)

        val reloadedTrips = TripStore(file).loadAll()
        assertEquals(setOf(11110), reloadedTrips.keys)
        assertEquals(updated, reloadedTrips[11110])
    }

    @Test
    fun deleteRemovesOnlyMatchingSigunguTrip() {
        val file = temporaryFolder.newFile("trips.json")
        val store = TripStore(file)
        val first = trip(11110, "jongno.jpg")
        val second = trip(26110, "jung.jpg")

        store.upsert(first)
        store.upsert(second)
        val deleted = store.delete(11110)

        assertEquals(first, deleted)
        assertNull(store.load(11110))
        assertEquals(second, store.load(26110))
    }

    @Test
    fun upsertAppliesActiveSharedSpaceWhenTripHasNoExplicitSharedSpace() {
        val file = temporaryFolder.newFile("trips-shared.json")
        val store = TripStore(file, activeSharedSpaceIdProvider = { "space-1" })

        store.upsert(trip(11110, "jongno.jpg"))
        store.upsert(trip(26110, "jung.jpg").copy(sharedSpaceId = "space-explicit"))

        assertEquals("space-1", TripStore(file).load(11110)?.sharedSpaceId)
        assertEquals("space-explicit", TripStore(file).load(26110)?.sharedSpaceId)
    }


    @Test
    fun corruptStoreReadQuarantinesRawFileBeforeReturningEmptyTrips() {
        val file = temporaryFolder.newFile("trips-corrupt.json")
        file.writeText("{not-json")

        val trips = TripStore(file).loadAll()
        val quarantinedFiles = file.parentFile?.listFiles { _, name ->
            name.startsWith("${file.name}.corrupt-")
        }.orEmpty()

        assertEquals(emptyMap<Int, Trip>(), trips)
        assertEquals(false, file.exists())
        assertEquals(1, quarantinedFiles.size)
        assertEquals("{not-json", quarantinedFiles.single().readText())
    }

    private fun trip(sigunguCode: Int, image: String) = Trip(
        sigunguCode = sigunguCode,
        images = listOf(image),
        startDateIso = "2026-05-01",
        endDateIso = "2026-05-02",
        memo = "memo-$sigunguCode",
        scale = 1f,
        centerX = 0f,
        centerY = 0f,
    )
}
