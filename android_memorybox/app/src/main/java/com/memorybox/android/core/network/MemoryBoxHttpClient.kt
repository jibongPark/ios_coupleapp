package com.memorybox.android.core.network

import java.io.IOException
import java.net.HttpURLConnection

enum class MemoryBoxHttpMethod(val wireName: String) {
    Get("GET"),
    Post("POST"),
    Put("PUT"),
    Patch("PATCH"),
    Delete("DELETE"),
}

data class MemoryBoxHttpRequest(
    val method: MemoryBoxHttpMethod,
    val path: String,
    val body: String? = null,
    val bearerToken: String? = null,
)

data class MemoryBoxHttpResponse(
    val statusCode: Int,
    val body: String,
) {
    val isSuccessful: Boolean
        get() = statusCode in 200..299

    val isUnauthorized: Boolean
        get() = statusCode == 401
}

interface MemoryBoxHttpClient {
    fun execute(request: MemoryBoxHttpRequest): MemoryBoxHttpResponse
}

class UrlConnectionMemoryBoxHttpClient(
    private val config: MemoryBoxConfig,
) : MemoryBoxHttpClient {
    override fun execute(request: MemoryBoxHttpRequest): MemoryBoxHttpResponse {
        val connection = config.urlFor(request.path).openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = request.method.wireName
            connection.connectTimeout = DEFAULT_TIMEOUT_MS
            connection.readTimeout = DEFAULT_TIMEOUT_MS
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Content-Type", "application/json")
            request.bearerToken
                ?.takeIf { it.isNotBlank() }
                ?.let { connection.setRequestProperty("Authorization", "Bearer $it") }

            val body = request.body
            if (body != null) {
                connection.doOutput = true
                connection.outputStream.use { stream ->
                    stream.write(body.toByteArray(Charsets.UTF_8))
                }
            }

            val statusCode = connection.responseCode
            val responseBody = readBody(connection, statusCode)
            MemoryBoxHttpResponse(statusCode = statusCode, body = responseBody)
        } finally {
            connection.disconnect()
        }
    }

    private fun readBody(connection: HttpURLConnection, statusCode: Int): String {
        val stream = if (statusCode in 200..299) {
            connection.inputStream
        } else {
            connection.errorStream ?: return ""
        }

        return try {
            stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
        } catch (_: IOException) {
            ""
        }
    }

    private companion object {
        const val DEFAULT_TIMEOUT_MS = 15_000
    }
}
