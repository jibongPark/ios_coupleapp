package com.memorybox.android.canvas

import com.memorybox.android.core.network.DataResult
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CanvasRepositoryTest {
    @Test
    fun appendPersistsAndFetchAfterSequenceReturnsNewerStrokes() {
        val repository = LocalCanvasRepository(CanvasJsonStore(tempFile()), idProvider = { "canvas-1" })
        val first = stroke(sequence = 1)
        val second = stroke(id = "stroke-2", sequence = 2)

        repository.appendStroke(first)
        repository.appendStroke(second)
        val result = repository.fetchStrokes("space-1", afterSequence = 1)

        assertTrue(result is DataResult.Success<*>)
        assertEquals(listOf(second), (result as DataResult.Success).data)
    }

    @Test
    fun clearCanvasRemovesLocalStrokesAndAdvancesCanvas() {
        val repository = LocalCanvasRepository(CanvasJsonStore(tempFile()), idProvider = { "canvas-1" })
        repository.appendStroke(stroke(sequence = 1))

        val clear = repository.clearCanvas("space-1")
        val strokes = repository.fetchStrokes("space-1", afterSequence = null)

        assertTrue(clear is DataResult.Success<*>)
        assertEquals(0, ((strokes as DataResult.Success).data).size)
    }

    @Test
    fun missingSharedSpaceFailsClearly() {
        val repository = LocalCanvasRepository(CanvasJsonStore(tempFile()))
        val result = repository.fetchCanvas("")

        assertTrue(result is DataResult.Failure)
        assertEquals("sharedSpaceId is required", (result as DataResult.Failure).message)
    }

    private fun stroke(id: String = "stroke-1", sequence: Int) = CanvasStroke(
        id = id,
        canvasId = "canvas-1",
        sharedSpaceId = "space-1",
        authorId = "me",
        sequence = sequence,
        tool = CanvasTool.Pen,
        colorHex = "#3D2C2E",
        lineWidth = 4f,
        points = listOf(CanvasPoint(0.1f, 0.2f)),
    )

    private fun tempFile(): File = kotlin.io.path.createTempDirectory("canvas-repository-test").toFile().resolve("canvas.json")
}
