package com.memorybox.android.canvas

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import java.io.File
import java.io.FileOutputStream

class CanvasSnapshotRenderer(
    private val width: Int = 800,
    private val height: Int = 800,
    private val backgroundColor: Int = Color.rgb(250, 237, 219),
) {
    fun render(strokes: List<CanvasStroke>): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(backgroundColor)
        strokes.sortedBy { it.sequence }.forEach { stroke -> drawStroke(canvas, stroke) }
        return bitmap
    }

    fun writePng(strokes: List<CanvasStroke>, file: File): File {
        file.parentFile?.mkdirs()
        FileOutputStream(file).use { out -> render(strokes).compress(Bitmap.CompressFormat.PNG, 100, out) }
        return file
    }

    private fun drawStroke(canvas: Canvas, stroke: CanvasStroke) {
        if (stroke.points.size < 2) return
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            strokeWidth = stroke.lineWidth
            color = if (stroke.tool == CanvasTool.Eraser) backgroundColor else runCatching { Color.parseColor(stroke.colorHex) }.getOrDefault(Color.rgb(61, 44, 46))
        }
        stroke.points.zipWithNext().forEach { (from, to) ->
            canvas.drawLine(from.x * width, from.y * height, to.x * width, to.y * height, paint)
        }
    }
}
