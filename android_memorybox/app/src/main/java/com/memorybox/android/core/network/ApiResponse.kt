package com.memorybox.android.core.network

import kotlinx.serialization.Serializable

@Serializable
data class ApiResponse<T>(
    val success: Boolean,
    val message: String = "",
    val data: T? = null,
)

sealed class DataResult<out T> {
    data class Success<T>(val data: T, val message: String = "") : DataResult<T>()
    data class Failure(val message: String, val cause: Throwable? = null) : DataResult<Nothing>()
}
