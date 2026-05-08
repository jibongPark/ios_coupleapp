package com.memorybox.android.core.network

import java.net.URL

data class MemoryBoxConfig(
    val baseUrl: String,
) {
    init {
        require(baseUrl.isNotBlank()) { "MemoryBox baseUrl must not be blank." }
    }

    internal fun urlFor(path: String): URL {
        val normalizedBase = baseUrl.trimEnd('/')
        val normalizedPath = path.trimStart('/')
        return URL("$normalizedBase/$normalizedPath")
    }
}
