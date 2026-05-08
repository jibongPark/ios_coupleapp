package com.memorybox.android.map.domain

import kotlinx.serialization.Serializable

data class GeoPoint(
    val lon: Double,
    val lat: Double,
)

data class SigunguPolygon(
    val code: Int,
    val name: String,
    val multiPolygon: List<List<List<GeoPoint>>>,
)

@Serializable
data class Trip(
    val sigunguCode: Int,
    val images: List<String> = emptyList(),
    val startDateIso: String,
    val endDateIso: String,
    val memo: String = "",
    val scale: Float = 1f,
    val centerX: Float = 0f,
    val centerY: Float = 0f,
)
