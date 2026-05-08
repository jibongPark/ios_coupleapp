package com.memorybox.android.map

import com.memorybox.android.map.data.TripImageFiles
import java.io.ByteArrayInputStream
import java.io.File
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class TripImageFilesTest {
    @get:Rule
    val temporaryFolder = TemporaryFolder()

    @Test
    fun copyInputStreamStoresBytesUnderJpegFilename() {
        val directory = temporaryFolder.newFolder("trip-images")
        val bytes = byteArrayOf(1, 2, 3, 4, 5)

        val filename = TripImageFiles.copyInputStream(
            inputStream = ByteArrayInputStream(bytes),
            imageDirectory = directory,
            filename = "trip-test.jpg",
        )

        assertTrue(filename.endsWith(".jpg"))
        assertArrayEquals(bytes, File(directory, filename).readBytes())
    }

    @Test
    fun deleteByFilenameRemovesOnlyFilesInsideImageDirectory() {
        val directory = temporaryFolder.newFolder("trip-images")
        val filename = TripImageFiles.copyInputStream(
            inputStream = ByteArrayInputStream(byteArrayOf(9)),
            imageDirectory = directory,
            filename = "trip-delete.jpg",
        )

        assertFalse(TripImageFiles.deleteByFilename(directory, "../outside.jpg"))
        assertTrue(TripImageFiles.deleteByFilename(directory, filename))
        assertFalse(File(directory, filename).exists())
    }
}
