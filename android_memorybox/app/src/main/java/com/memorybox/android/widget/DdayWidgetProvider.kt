package com.memorybox.android.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import com.memorybox.android.R
import com.memorybox.android.widget.data.DdayImageFiles
import com.memorybox.android.widget.data.DdayWidgetStore
import com.memorybox.android.widget.domain.DdayWidgetRenderState
import com.memorybox.android.widget.domain.WidgetAlign
import java.io.File

class DdayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(widgetId, buildViews(context))
        }
    }

    internal fun buildViews(context: Context): RemoteViews {
        val state = DdayWidgetRenderState.from(DdayWidgetStore.selected(context))
        return RemoteViews(context.packageName, R.layout.dday_widget).apply {
            applyImage(context, state.imagePath)
            applyTextState(state)
        }
    }

    private fun RemoteViews.applyTextState(state: DdayWidgetRenderState) {
        val showCombined = state.useCombinedTextGroup
        setViewVisibility(R.id.dday_combined_group, showCombined.toVisibility())
        setViewVisibility(R.id.dday_text, (state.showDate && !showCombined).toVisibility())
        setViewVisibility(R.id.dday_title, (state.showTitle && !showCombined).toVisibility())

        setTextViewText(R.id.dday_combined_date, state.dateText)
        setTextViewText(R.id.dday_combined_title, state.titleText)
        setTextViewText(R.id.dday_text, state.dateText)
        setTextViewText(R.id.dday_title, state.titleText)

        setInt(R.id.dday_combined_group, "setGravity", state.titleAlignment.toGravity())
        setInt(R.id.dday_text, "setGravity", state.dateAlignment.toGravity())
        setInt(R.id.dday_title, "setGravity", state.titleAlignment.toGravity())
    }

    private fun RemoteViews.applyImage(context: Context, imagePath: String) {
        val bitmap = decodeWidgetImage(context, imagePath)
        if (bitmap == null) {
            setViewVisibility(R.id.dday_background_image, View.GONE)
        } else {
            setImageViewBitmap(R.id.dday_background_image, bitmap)
            setViewVisibility(R.id.dday_background_image, View.VISIBLE)
        }
    }

    private fun decodeWidgetImage(context: Context, imagePath: String): Bitmap? {
        if (imagePath.isBlank()) return null

        val managedFile = DdayImageFiles.fileFor(context, imagePath)?.takeIf { it.isFile }
        val directFile = File(imagePath).takeIf { it.isFile }
        val appPrivateFile = File(context.filesDir, imagePath).takeIf { it.isFile }
        val imageFile = when {
            managedFile != null -> managedFile
            directFile != null -> directFile
            appPrivateFile != null -> appPrivateFile
            else -> return null
        }

        return runCatching { BitmapFactory.decodeFile(imageFile.absolutePath) }.getOrNull()
    }

    private fun WidgetAlign.toGravity(): Int {
        return when (this) {
            WidgetAlign.TopLeft -> Gravity.TOP or Gravity.START
            WidgetAlign.TopCenter -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
            WidgetAlign.TopRight -> Gravity.TOP or Gravity.END
            WidgetAlign.CenterLeft -> Gravity.CENTER_VERTICAL or Gravity.START
            WidgetAlign.Center -> Gravity.CENTER
            WidgetAlign.CenterRight -> Gravity.CENTER_VERTICAL or Gravity.END
            WidgetAlign.BottomLeft -> Gravity.BOTTOM or Gravity.START
            WidgetAlign.BottomCenter -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            WidgetAlign.BottomRight -> Gravity.BOTTOM or Gravity.END
        }
    }

    private fun Boolean.toVisibility(): Int = if (this) View.VISIBLE else View.GONE
}
