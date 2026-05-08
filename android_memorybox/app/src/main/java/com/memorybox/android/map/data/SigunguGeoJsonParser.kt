package com.memorybox.android.map.data

import com.memorybox.android.map.domain.GeoPoint
import com.memorybox.android.map.domain.SigunguPolygon
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.double
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

object SigunguGeoJsonParser {
    fun parse(geoJson: String): List<SigunguPolygon> {
        val root = Json.parseToJsonElement(geoJson).jsonObject
        val features = root["features"]?.jsonArray ?: return emptyList()

        return features.mapNotNull { feature ->
            val featureObject = feature as? JsonObject ?: return@mapNotNull null
            val properties = featureObject["properties"]?.jsonObject ?: return@mapNotNull null
            val geometry = featureObject["geometry"]?.jsonObject ?: return@mapNotNull null

            val code = properties["SIGUNGU_CD"]
                ?.jsonPrimitive
                ?.content
                ?.toIntOrNull()
                ?: return@mapNotNull null
            val name = properties["SIGUNGU_NM"]
                ?.jsonPrimitive
                ?.content
                ?: return@mapNotNull null
            val coordinates = geometry["coordinates"] as? JsonArray ?: return@mapNotNull null

            SigunguPolygon(
                code = code,
                name = name,
                multiPolygon = coordinates.toMultiPolygon(),
            )
        }
    }

    private fun JsonArray.toMultiPolygon(): List<List<List<GeoPoint>>> =
        map { polygon ->
            polygon.jsonArray.map { ring ->
                ring.jsonArray.mapNotNull { coordinate ->
                    coordinate.toGeoPointOrNull()
                }
            }
        }

    private fun JsonElement.toGeoPointOrNull(): GeoPoint? {
        val coordinate = this as? JsonArray ?: return null
        if (coordinate.size < 2) return null

        return GeoPoint(
            lon = coordinate[0].jsonPrimitive.double,
            lat = coordinate[1].jsonPrimitive.double,
        )
    }
}
