package com.memorybox.android.map.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.memorybox.android.map.data.SigunguGeoJsonParser
import com.memorybox.android.map.data.TripImageFiles
import com.memorybox.android.map.data.TripStore
import com.memorybox.android.map.domain.GeoPoint
import com.memorybox.android.map.domain.SigunguPolygon
import com.memorybox.android.map.domain.Trip
import java.time.LocalDate

@Composable
fun MapScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val tripStore = remember(context) { TripStore.appPrivate(context) }
    var polygons by remember { mutableStateOf<List<SigunguPolygon>>(emptyList()) }
    var error by remember { mutableStateOf<String?>(null) }
    val trips = remember { mutableStateMapOf<Int, Trip>() }
    var editorState by remember { mutableStateOf<TripEditorState?>(null) }
    var imageError by remember { mutableStateOf<String?>(null) }

    fun openEditor(polygon: SigunguPolygon) {
        val trip = trips[polygon.code]
        val today = LocalDate.now().toString()
        editorState = TripEditorState(
            polygon = polygon,
            images = trip?.images.orEmpty(),
            startDateIso = trip?.startDateIso ?: today,
            endDateIso = trip?.endDateIso ?: today,
            memo = trip?.memo.orEmpty(),
            scale = trip?.scale ?: 1f,
            centerX = trip?.centerX ?: 0f,
            centerY = trip?.centerY ?: 0f,
        )
        imageError = null
    }

    fun discardNewImagesAndClose() {
        editorState?.newImages.orEmpty().forEach { filename ->
            TripImageFiles.deleteByFilename(context, filename)
        }
        editorState = null
        imageError = null
    }

    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        runCatching { TripImageFiles.copyUri(context, uri) }
            .onSuccess { filename ->
                editorState = editorState?.let {
                    it.copy(
                        images = it.images + filename,
                        newImages = it.newImages + filename,
                    )
                }
                imageError = null
            }
            .onFailure {
                imageError = it.message ?: "이미지를 저장하지 못했습니다."
            }
    }

    LaunchedEffect(Unit) {
        runCatching {
            context.assets.open("sigungu.geojson").bufferedReader().use { it.readText() }
        }.mapCatching { json ->
            SigunguGeoJsonParser.parse(json)
        }.onSuccess {
            polygons = it
        }.onFailure {
            error = it.message ?: "지도 데이터를 불러오지 못했습니다."
        }
    }

    LaunchedEffect(tripStore) {
        trips.clear()
        trips.putAll(tripStore.loadAll())
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(12.dp),
    ) {
        Text("여행지도", style = MaterialTheme.typography.titleLarge)
        Box(Modifier.fillMaxSize()) {
            if (error != null) {
                Text(error.orEmpty())
            } else if (polygons.isEmpty()) {
                Text("Loading GeoJSON...")
            } else {
                SigunguCanvas(
                    polygons = polygons,
                    trips = trips,
                    selectedCode = editorState?.polygon?.code,
                    onPolygonTapped = ::openEditor,
                )
            }
        }
    }

    editorState?.let { state ->
        TripEditorDialog(
            state = state,
            imageError = imageError,
            hasExistingTrip = trips.containsKey(state.polygon.code),
            onStateChange = { editorState = it },
            onAddImage = { imagePicker.launch("image/*") },
            onDeleteImage = onDeleteImage@ { filename ->
                val current = editorState ?: return@onDeleteImage
                val isNewImage = filename in current.newImages
                if (isNewImage) {
                    TripImageFiles.deleteByFilename(context, filename)
                }
                editorState = current.copy(
                    images = current.images - filename,
                    newImages = current.newImages - filename,
                    removedImages = if (isNewImage) {
                        current.removedImages
                    } else {
                        current.removedImages + filename
                    },
                )
            },
            onDismiss = ::discardNewImagesAndClose,
            onDeleteTrip = onDeleteTrip@ {
                val current = editorState ?: return@onDeleteTrip
                val persistedImages = trips[current.polygon.code]?.images.orEmpty()
                (persistedImages + current.images + current.newImages + current.removedImages)
                    .distinct()
                    .forEach { filename -> TripImageFiles.deleteByFilename(context, filename) }
                tripStore.delete(current.polygon.code)
                trips.remove(current.polygon.code)
                editorState = null
                imageError = null
            },
            onSave = onSave@ {
                val current = editorState ?: return@onSave
                val trip = current.toTrip()
                tripStore.upsert(trip)
                trips[trip.sigunguCode] = trip
                current.removedImages.distinct().forEach { filename ->
                    TripImageFiles.deleteByFilename(context, filename)
                }
                editorState = null
                imageError = null
            },
        )
    }
}

@Composable
private fun SigunguCanvas(
    polygons: List<SigunguPolygon>,
    trips: Map<Int, Trip>,
    selectedCode: Int?,
    onPolygonTapped: (SigunguPolygon) -> Unit,
) {
    var canvasSize by remember { mutableStateOf(IntSize.Zero) }

    Canvas(
        Modifier
            .fillMaxSize()
            .onSizeChanged { canvasSize = it }
            .pointerInput(polygons, canvasSize) {
                detectTapGestures { tapOffset ->
                    findPolygonAt(polygons, tapOffset, canvasSize)?.let(onPolygonTapped)
                }
            },
    ) {
        val bounds = polygons.geoBounds() ?: return@Canvas

        polygons.forEach { polygon ->
            polygon.multiPolygon.forEach { rings ->
                rings.forEach { ring ->
                    val path = Path()
                    ring.forEachIndexed { index, point ->
                        val offset = project(point, bounds, size)
                        if (index == 0) {
                            path.moveTo(offset.x, offset.y)
                        } else {
                            path.lineTo(offset.x, offset.y)
                        }
                    }
                    path.close()
                    val fillColor = when {
                        polygon.code == selectedCode -> Color(0xFF4267B2).copy(alpha = 0.28f)
                        trips.containsKey(polygon.code) -> Color(0xFFC1765D).copy(alpha = 0.24f)
                        else -> Color.Transparent
                    }
                    if (fillColor != Color.Transparent) {
                        drawPath(path, color = fillColor)
                    }
                    drawPath(path, color = Color.Gray, style = Stroke(width = 1f))
                }
            }
        }

        polygons.take(30).forEach { polygon ->
            val firstRing = polygon.multiPolygon.firstOrNull()?.firstOrNull().orEmpty()
            if (firstRing.isNotEmpty()) {
                val lon = firstRing.map { it.lon }.average()
                val lat = firstRing.map { it.lat }.average()
                val center = project(GeoPoint(lon = lon, lat = lat), bounds, size)
                drawCircle(
                    color = if (trips.containsKey(polygon.code)) Color(0xFFC1765D) else Color.DarkGray,
                    radius = if (trips.containsKey(polygon.code)) 4f else 2.5f,
                    center = center,
                )
            }
        }
    }
}

@Composable
private fun TripEditorDialog(
    state: TripEditorState,
    imageError: String?,
    hasExistingTrip: Boolean,
    onStateChange: (TripEditorState) -> Unit,
    onAddImage: () -> Unit,
    onDeleteImage: (String) -> Unit,
    onDismiss: () -> Unit,
    onDeleteTrip: () -> Unit,
    onSave: () -> Unit,
) {
    val hasValidDates = isValidIsoDate(state.startDateIso) && isValidIsoDate(state.endDateIso)

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 640.dp),
            shape = MaterialTheme.shapes.medium,
            tonalElevation = 6.dp,
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(state.polygon.name, style = MaterialTheme.typography.titleLarge)
                OutlinedTextField(
                    value = state.startDateIso,
                    onValueChange = { onStateChange(state.copy(startDateIso = it)) },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("시작일 yyyy-MM-dd") },
                    isError = state.startDateIso.isNotBlank() && !isValidIsoDate(state.startDateIso),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = state.endDateIso,
                    onValueChange = { onStateChange(state.copy(endDateIso = it)) },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("종료일 yyyy-MM-dd") },
                    isError = state.endDateIso.isNotBlank() && !isValidIsoDate(state.endDateIso),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = state.memo,
                    onValueChange = { onStateChange(state.copy(memo = it)) },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("메모") },
                    minLines = 3,
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text("사진 ${state.images.size}", style = MaterialTheme.typography.titleMedium)
                    OutlinedButton(onClick = onAddImage) {
                        Text("사진 추가")
                    }
                }
                imageError?.let {
                    Text(it, color = MaterialTheme.colorScheme.error)
                }
                if (state.images.isEmpty()) {
                    Text("저장된 사진이 없습니다.", style = MaterialTheme.typography.bodyMedium)
                } else {
                    state.images.forEach { filename ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(
                                text = filename,
                                modifier = Modifier.weight(1f),
                                maxLines = 1,
                            )
                            TextButton(onClick = { onDeleteImage(filename) }) {
                                Text("삭제")
                            }
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    TextButton(
                        modifier = Modifier.weight(1f),
                        onClick = onDismiss,
                    ) {
                        Text("취소")
                    }
                    if (hasExistingTrip) {
                        OutlinedButton(
                            modifier = Modifier.weight(1f),
                            onClick = onDeleteTrip,
                        ) {
                            Text("여행 삭제")
                        }
                    }
                    Button(
                        modifier = Modifier.weight(1f),
                        enabled = hasValidDates,
                        onClick = onSave,
                    ) {
                        Text("저장")
                    }
                }
            }
        }
    }
}

private data class TripEditorState(
    val polygon: SigunguPolygon,
    val images: List<String>,
    val startDateIso: String,
    val endDateIso: String,
    val memo: String,
    val scale: Float,
    val centerX: Float,
    val centerY: Float,
    val newImages: List<String> = emptyList(),
    val removedImages: List<String> = emptyList(),
) {
    fun toTrip(): Trip = Trip(
        sigunguCode = polygon.code,
        images = images,
        startDateIso = startDateIso,
        endDateIso = endDateIso,
        memo = memo,
        scale = scale,
        centerX = centerX,
        centerY = centerY,
    )
}

private data class GeoBounds(
    val minLon: Double,
    val maxLon: Double,
    val minLat: Double,
    val maxLat: Double,
)

private fun List<SigunguPolygon>.geoBounds(): GeoBounds? {
    val points = flatMap { polygon ->
        polygon.multiPolygon.flatten().flatten()
    }
    if (points.isEmpty()) return null

    return GeoBounds(
        minLon = points.minOf { it.lon },
        maxLon = points.maxOf { it.lon },
        minLat = points.minOf { it.lat },
        maxLat = points.maxOf { it.lat },
    )
}

private fun project(point: GeoPoint, bounds: GeoBounds, size: Size): Offset {
    val lonSpan = (bounds.maxLon - bounds.minLon).coerceAtLeast(0.0001)
    val latSpan = (bounds.maxLat - bounds.minLat).coerceAtLeast(0.0001)
    val x = ((point.lon - bounds.minLon) / lonSpan).toFloat() * size.width
    val y = size.height - ((point.lat - bounds.minLat) / latSpan).toFloat() * size.height
    return Offset(x, y)
}

private fun findPolygonAt(
    polygons: List<SigunguPolygon>,
    tapOffset: Offset,
    canvasSize: IntSize,
): SigunguPolygon? {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return null
    val bounds = polygons.geoBounds() ?: return null
    val size = Size(canvasSize.width.toFloat(), canvasSize.height.toFloat())

    return polygons.firstOrNull { polygon ->
        polygon.multiPolygon.any { rings ->
            rings.any { ring ->
                containsPoint(
                    ring = ring.map { point -> project(point, bounds, size) },
                    point = tapOffset,
                )
            }
        }
    }
}

private fun containsPoint(ring: List<Offset>, point: Offset): Boolean {
    if (ring.size < 3) return false

    var inside = false
    var previousIndex = ring.lastIndex
    ring.indices.forEach { index ->
        val current = ring[index]
        val previous = ring[previousIndex]
        val intersects = (current.y > point.y) != (previous.y > point.y) &&
            point.x < (previous.x - current.x) * (point.y - current.y) / (previous.y - current.y) + current.x
        if (intersects) inside = !inside
        previousIndex = index
    }
    return inside
}

private fun isValidIsoDate(value: String): Boolean =
    runCatching { LocalDate.parse(value) }.isSuccess
