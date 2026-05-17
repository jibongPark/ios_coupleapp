package com.memorybox.android.canvas

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.math.max
import kotlin.math.min

@Serializable
data class SharedCanvas(
    val id: String,
    val sharedSpaceId: String,
    val title: String? = null,
    val latestSnapshotVersion: Int = 0,
    val latestSnapshotUrl: String? = null,
    val localSnapshotPath: String? = null,
)

@Serializable
data class CanvasStroke(
    val id: String,
    val canvasId: String,
    val sharedSpaceId: String,
    val authorId: String,
    val sequence: Int,
    val tool: CanvasTool,
    val colorHex: String,
    val lineWidth: Float,
    val points: List<CanvasPoint>,
    val pendingSync: Boolean = true,
) {
    fun normalized(): CanvasStroke = copy(points = points.map { it.normalized() })
}

@Serializable
enum class CanvasTool {
    @SerialName("pen") Pen,
    @SerialName("eraser") Eraser,
}

@Serializable
data class CanvasPoint(
    val x: Float,
    val y: Float,
    val t: Double? = null,
    val pressure: Float? = null,
) {
    fun normalized(): CanvasPoint = copy(
        x = x.coerceNormalized(),
        y = y.coerceNormalized(),
        pressure = pressure?.coerceNormalized(),
    )
}

@Serializable
data class CanvasSnapshot(
    val id: String,
    val canvasId: String,
    val sharedSpaceId: String,
    val version: Int,
    val imageUrl: String? = null,
    val localPath: String? = null,
    val width: Int,
    val height: Int,
)

internal fun Float.coerceNormalized(): Float = min(1f, max(0f, this))
