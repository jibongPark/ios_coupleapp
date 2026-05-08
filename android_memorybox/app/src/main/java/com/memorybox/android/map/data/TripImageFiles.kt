package com.memorybox.android.map.data

import android.content.Context
import android.net.Uri
import java.io.File
import java.io.InputStream
import java.util.UUID

object TripImageFiles {
    private const val DIRECTORY_NAME = "trip_images"
    private const val JPEG_EXTENSION = ".jpg"

    fun copyUri(context: Context, uri: Uri): String {
        val inputStream = context.contentResolver.openInputStream(uri)
            ?: error("Unable to open selected image.")
        return inputStream.use {
            copyInputStream(
                inputStream = it,
                imageDirectory = appPrivateImageDirectory(context),
            )
        }
    }

    fun copyInputStream(
        inputStream: InputStream,
        imageDirectory: File,
        filename: String = newJpegFilename(),
    ): String {
        require(isSafeFilename(filename)) { "Image filename must not contain path separators." }

        imageDirectory.mkdirs()
        File(imageDirectory, filename).outputStream().use { outputStream ->
            inputStream.copyTo(outputStream)
        }
        return filename
    }

    fun deleteByFilename(context: Context, filename: String): Boolean =
        deleteByFilename(appPrivateImageDirectory(context), filename)

    fun deleteByFilename(imageDirectory: File, filename: String): Boolean {
        if (!isSafeFilename(filename)) return false
        val target = File(imageDirectory, filename)
        return target.isFile && target.delete()
    }

    fun fileFor(context: Context, filename: String): File? {
        if (!isSafeFilename(filename)) return null
        return File(appPrivateImageDirectory(context), filename)
    }

    fun appPrivateImageDirectory(context: Context): File = File(context.filesDir, DIRECTORY_NAME)

    private fun newJpegFilename(): String = "trip-${UUID.randomUUID()}$JPEG_EXTENSION"

    private fun isSafeFilename(filename: String): Boolean =
        filename.isNotBlank() &&
            File(filename).name == filename &&
            filename.endsWith(JPEG_EXTENSION, ignoreCase = true)
}
