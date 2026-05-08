package com.memorybox.android.widget.data

import java.io.ByteArrayInputStream
import java.io.File
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class DdayImageFilesTest {
    @get:Rule
    val temporaryFolder = TemporaryFolder()

    @Test
    fun copyInputStreamStoresBytesUnderDdayJpegFilename() {
        val directory = temporaryFolder.newFolder("dday-images")
        val bytes = byteArrayOf(1, 2, 3, 4, 5)

        val filename = DdayImageFiles.copyInputStream(
            inputStream = ByteArrayInputStream(bytes),
            imageDirectory = directory,
            filename = "dday-test.jpg",
        )

        assertTrue(filename.endsWith(".jpg"))
        assertArrayEquals(bytes, File(directory, filename).readBytes())
    }

    @Test
    fun deleteByFilenameRemovesOnlyManagedFilesInsideImageDirectory() {
        val directory = temporaryFolder.newFolder("dday-images")
        val filename = DdayImageFiles.copyInputStream(
            inputStream = ByteArrayInputStream(byteArrayOf(9)),
            imageDirectory = directory,
            filename = "dday-delete.jpg",
        )

        assertFalse(DdayImageFiles.deleteByFilename(directory, "../outside.jpg"))
        assertFalse(DdayImageFiles.deleteByFilename(directory, "trip-delete.jpg"))
        assertTrue(DdayImageFiles.deleteByFilename(directory, filename))
        assertFalse(File(directory, filename).exists())
    }
}
