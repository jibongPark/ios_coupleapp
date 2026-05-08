package com.memorybox.android.map

import com.memorybox.android.map.data.SigunguGeoJsonParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GeoJsonParserTest {
    @Test
    fun parsesSigunguNameCodeAndPolygonCoordinates() {
        val json = """
            {
              "type": "FeatureCollection",
              "features": [
                {
                  "type": "Feature",
                  "properties": {
                    "SIGUNGU_CD": "11110",
                    "SIGUNGU_NM": "종로구"
                  },
                  "geometry": {
                    "type": "MultiPolygon",
                    "coordinates": [[[[126.0,37.0],[127.0,37.0],[127.0,38.0],[126.0,37.0]]]]
                  }
                }
              ]
            }
        """.trimIndent()

        val polygons = SigunguGeoJsonParser.parse(json)

        assertEquals(1, polygons.size)
        assertEquals(11110, polygons.first().code)
        assertEquals("종로구", polygons.first().name)
        assertEquals(1, polygons.first().multiPolygon.size)
        assertTrue(polygons.first().multiPolygon.first().first().isNotEmpty())
    }
}
