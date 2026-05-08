package com.memorybox.android.canvas

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.memorybox.android.core.network.DataResult
import java.io.File

@Composable
fun CanvasScreen(
    sharedSpaceId: String?,
    repository: CanvasRepository,
    modifier: Modifier = Modifier,
    snapshotThrottle: SnapshotThrottle = remember { SnapshotThrottle() },
    renderer: CanvasSnapshotRenderer = remember { CanvasSnapshotRenderer() },
) {
    if (sharedSpaceId.isNullOrBlank()) {
        Column(modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("우리 낙서장")
            Text("페어링 후 서로의 낙서를 공유할 수 있어요.")
        }
        return
    }

    val context = LocalContext.current
    var canvas by remember(sharedSpaceId) { mutableStateOf<SharedCanvas?>(null) }
    var strokes by remember(sharedSpaceId) { mutableStateOf(emptyList<CanvasStroke>()) }
    var currentStroke by remember { mutableStateOf<CanvasStroke?>(null) }
    var selectedTool by remember { mutableStateOf(CanvasTool.Pen) }
    var selectedColor by remember { mutableStateOf("#3D2C2E") }
    var lineWidth by remember { mutableStateOf(6f) }
    var message by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(sharedSpaceId) {
        when (val result = repository.fetchCanvas(sharedSpaceId)) {
            is DataResult.Success -> canvas = result.data
            is DataResult.Failure -> message = result.message
        }
        when (val result = repository.fetchStrokes(sharedSpaceId)) {
            is DataResult.Success -> strokes = result.data
            is DataResult.Failure -> message = result.message
        }
    }

    Column(modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("우리 낙서장")
        message?.let { Text(it) }
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(420.dp)
                .background(Color(0xFFFAEDDB), RoundedCornerShape(24.dp))
                .pointerInput(canvas?.id, selectedTool, selectedColor, lineWidth) {
                    detectDragGestures(
                        onDragStart = { offset ->
                            val activeCanvas = canvas ?: return@detectDragGestures
                            val sequence = (strokes.maxOfOrNull { it.sequence } ?: 0) + 1
                            currentStroke = CanvasStroke(
                                id = "stroke-${System.currentTimeMillis()}",
                                canvasId = activeCanvas.id,
                                sharedSpaceId = sharedSpaceId,
                                authorId = "local",
                                sequence = sequence,
                                tool = selectedTool,
                                colorHex = selectedColor,
                                lineWidth = lineWidth,
                                points = listOf(offset.toCanvasPoint(size.width.toFloat(), size.height.toFloat())),
                            )
                        },
                        onDrag = { change, _ ->
                            currentStroke = currentStroke?.copy(points = currentStroke!!.points + change.position.toCanvasPoint(size.width.toFloat(), size.height.toFloat()))
                        },
                        onDragEnd = {
                            currentStroke?.let { stroke ->
                                val stored = when (val result = repository.appendStroke(stroke)) {
                                    is DataResult.Success -> result.data
                                    is DataResult.Failure -> {
                                        message = result.message
                                        stroke
                                    }
                                }
                                strokes = strokes + stored
                                if (snapshotThrottle.shouldUpdate()) {
                                    val file = File(context.filesDir, "canvas/snapshots/${sharedSpaceId}.png")
                                    renderer.writePng(strokes, file)
                                    repository.updateSnapshot(
                                        CanvasSnapshot(
                                            id = "snapshot-${System.currentTimeMillis()}",
                                            canvasId = stored.canvasId,
                                            sharedSpaceId = sharedSpaceId,
                                            version = stored.sequence,
                                            localPath = file.absolutePath,
                                            width = 800,
                                            height = 800,
                                        ),
                                    )
                                }
                            }
                            currentStroke = null
                        },
                    )
                },
        ) {
            (strokes + listOfNotNull(currentStroke)).sortedBy { it.sequence }.forEach { stroke ->
                stroke.points.zipWithNext().forEach { (from, to) ->
                    drawLine(
                        color = if (stroke.tool == CanvasTool.Eraser) Color(0xFFFAEDDB) else Color(android.graphics.Color.parseColor(stroke.colorHex)),
                        start = Offset(from.x * size.width, from.y * size.height),
                        end = Offset(to.x * size.width, to.y * size.height),
                        strokeWidth = stroke.lineWidth,
                        cap = StrokeCap.Round,
                    )
                }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            FilterChip(selected = selectedTool == CanvasTool.Pen, onClick = { selectedTool = CanvasTool.Pen }, label = { Text("펜") })
            FilterChip(selected = selectedTool == CanvasTool.Eraser, onClick = { selectedTool = CanvasTool.Eraser }, label = { Text("지우개") })
            Button(onClick = { selectedColor = "#D96C4A" }) { Text("테라코타") }
            Button(onClick = {
                repository.clearCanvas(sharedSpaceId)
                strokes = emptyList()
            }) { Text("전체 지우기") }
        }
        Slider(value = lineWidth, onValueChange = { lineWidth = it }, valueRange = 2f..24f)
    }
}

private fun Offset.toCanvasPoint(width: Float, height: Float): CanvasPoint = CanvasPoint(
    x = x / width.coerceAtLeast(1f),
    y = y / height.coerceAtLeast(1f),
    t = System.currentTimeMillis().toDouble(),
).normalized()
