package com.memorybox.android.canvas

import android.content.Context
import com.memorybox.android.core.network.DataResult
import java.io.File
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

interface CanvasRepository {
    fun fetchCanvas(sharedSpaceId: String): DataResult<SharedCanvas>
    fun fetchStrokes(sharedSpaceId: String, afterSequence: Int? = null): DataResult<List<CanvasStroke>>
    fun appendStroke(stroke: CanvasStroke): DataResult<CanvasStroke>
    fun clearCanvas(sharedSpaceId: String): DataResult<SharedCanvas>
    fun updateSnapshot(snapshot: CanvasSnapshot): DataResult<CanvasSnapshot>
}

@Serializable
data class CanvasStoreSnapshot(
    val canvases: List<SharedCanvas> = emptyList(),
    val strokes: List<CanvasStroke> = emptyList(),
    val snapshots: List<CanvasSnapshot> = emptyList(),
    val lastSyncedSequenceBySharedSpaceId: Map<String, Int> = emptyMap(),
)

class CanvasJsonStore(
    private val file: File,
    private val json: Json = Json { encodeDefaults = true; ignoreUnknownKeys = true; prettyPrint = true },
) {
    @Synchronized
    fun read(): CanvasStoreSnapshot {
        if (!file.exists()) return CanvasStoreSnapshot()
        return runCatching { json.decodeFromString<CanvasStoreSnapshot>(file.readText()) }.getOrDefault(CanvasStoreSnapshot())
    }

    @Synchronized
    fun write(snapshot: CanvasStoreSnapshot) {
        file.parentFile?.mkdirs()
        file.writeText(json.encodeToString(snapshot))
    }

    companion object {
        fun appPrivate(context: Context): CanvasJsonStore =
            CanvasJsonStore(File(context.filesDir, "canvas/canvas_store.json"))
    }
}

class LocalCanvasRepository(
    private val store: CanvasJsonStore,
    private val idProvider: () -> String = { "canvas-${System.currentTimeMillis()}" },
) : CanvasRepository {
    override fun fetchCanvas(sharedSpaceId: String): DataResult<SharedCanvas> {
        val spaceId = sharedSpaceId.validSharedSpaceId() ?: return DataResult.Failure("sharedSpaceId is required")
        val snapshot = store.read()
        snapshot.canvases.firstOrNull { it.sharedSpaceId == spaceId }?.let { return DataResult.Success(it) }
        val canvas = SharedCanvas(id = idProvider(), sharedSpaceId = spaceId, title = "우리 낙서장")
        store.write(snapshot.copy(canvases = snapshot.canvases + canvas))
        return DataResult.Success(canvas)
    }

    override fun fetchStrokes(sharedSpaceId: String, afterSequence: Int?): DataResult<List<CanvasStroke>> {
        val spaceId = sharedSpaceId.validSharedSpaceId() ?: return DataResult.Failure("sharedSpaceId is required")
        val strokes = store.read().strokes
            .filter { it.sharedSpaceId == spaceId && (afterSequence == null || it.sequence > afterSequence) }
            .sortedBy { it.sequence }
        return DataResult.Success(strokes)
    }

    override fun appendStroke(stroke: CanvasStroke): DataResult<CanvasStroke> {
        stroke.sharedSpaceId.validSharedSpaceId() ?: return DataResult.Failure("sharedSpaceId is required")
        val snapshot = store.read()
        val normalized = stroke.normalized().copy(pendingSync = true)
        store.write(snapshot.copy(strokes = snapshot.strokes.filterNot { it.id == normalized.id } + normalized))
        return DataResult.Success(normalized)
    }

    override fun clearCanvas(sharedSpaceId: String): DataResult<SharedCanvas> {
        val spaceId = sharedSpaceId.validSharedSpaceId() ?: return DataResult.Failure("sharedSpaceId is required")
        val snapshot = store.read()
        val existing = snapshot.canvases.firstOrNull { it.sharedSpaceId == spaceId }
        val canvas = (existing ?: SharedCanvas(id = idProvider(), sharedSpaceId = spaceId, title = "우리 낙서장"))
            .copy(latestSnapshotVersion = (existing?.latestSnapshotVersion ?: 0) + 1)
        store.write(
            snapshot.copy(
                canvases = snapshot.canvases.filterNot { it.sharedSpaceId == spaceId } + canvas,
                strokes = snapshot.strokes.filterNot { it.sharedSpaceId == spaceId },
            ),
        )
        return DataResult.Success(canvas)
    }

    override fun updateSnapshot(snapshot: CanvasSnapshot): DataResult<CanvasSnapshot> {
        snapshot.sharedSpaceId.validSharedSpaceId() ?: return DataResult.Failure("sharedSpaceId is required")
        val current = store.read()
        val canvases = current.canvases.map {
            if (it.sharedSpaceId == snapshot.sharedSpaceId) it.copy(
                latestSnapshotVersion = snapshot.version,
                latestSnapshotUrl = snapshot.imageUrl,
                localSnapshotPath = snapshot.localPath,
            ) else it
        }
        store.write(
            current.copy(
                canvases = canvases,
                snapshots = current.snapshots.filterNot { it.sharedSpaceId == snapshot.sharedSpaceId && it.canvasId == snapshot.canvasId } + snapshot,
            ),
        )
        return DataResult.Success(snapshot)
    }
}

internal fun String.validSharedSpaceId(): String? = trim().takeIf { it.isNotEmpty() }
