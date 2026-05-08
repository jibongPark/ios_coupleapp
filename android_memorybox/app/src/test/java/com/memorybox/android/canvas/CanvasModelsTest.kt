package com.memorybox.android.canvas

import kotlin.test.assertEquals
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.junit.Test

class CanvasModelsTest {
    private val json = Json { encodeDefaults = true; ignoreUnknownKeys = true }

    @Test
    fun strokeJsonRoundTripPreservesNormalizedPoints() {
        val stroke = CanvasStroke(
            id = "stroke-1",
            canvasId = "canvas-1",
            sharedSpaceId = "space-1",
            authorId = "user-1",
            sequence = 7,
            tool = CanvasTool.Pen,
            colorHex = "#3D2C2E",
            lineWidth = 6f,
            points = listOf(CanvasPoint(1.2f, -0.4f, t = 10.0, pressure = 0.8f)),
        ).normalized()

        val decoded = json.decodeFromString<CanvasStroke>(json.encodeToString(stroke))

        assertEquals(1.0f, decoded.points.single().x)
        assertEquals(0.0f, decoded.points.single().y)
        assertEquals(CanvasTool.Pen, decoded.tool)
        assertEquals("space-1", decoded.sharedSpaceId)
    }
}
