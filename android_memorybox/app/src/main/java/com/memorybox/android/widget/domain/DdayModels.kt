package com.memorybox.android.widget.domain

import com.memorybox.android.core.date.MemoryBoxDates
import java.time.LocalDate
import java.util.UUID
import kotlinx.serialization.Serializable

enum class WidgetAlign {
    TopLeft,
    TopCenter,
    TopRight,
    CenterLeft,
    Center,
    CenterRight,
    BottomLeft,
    BottomCenter,
    BottomRight,
}

@Serializable
data class DdayWidgetItem(
    val id: String = UUID.randomUUID().toString(),
    val title: String = "",
    val memo: String = "",
    val startDateIso: String = LocalDate.now().toString(),
    val imagePath: String = "",
    val isShowDate: Boolean = true,
    val dateAlignment: WidgetAlign = WidgetAlign.Center,
    val isShowTitle: Boolean = true,
    val titleAlignment: WidgetAlign = WidgetAlign.Center,
) {
    val startDate: LocalDate
        get() = LocalDate.parse(startDateIso)
}

data class DdayWidgetRenderState(
    val titleText: String,
    val dateText: String,
    val showTitle: Boolean,
    val showDate: Boolean,
    val titleAlignment: WidgetAlign,
    val dateAlignment: WidgetAlign,
    val imagePath: String,
) {
    val useCombinedTextGroup: Boolean
        get() = showTitle && showDate && titleAlignment == dateAlignment

    companion object {
        fun from(item: DdayWidgetItem?, today: LocalDate = LocalDate.now()): DdayWidgetRenderState {
            if (item == null) {
                return DdayWidgetRenderState(
                    titleText = "MemoryBox",
                    dateText = "No data",
                    showTitle = true,
                    showDate = true,
                    titleAlignment = WidgetAlign.Center,
                    dateAlignment = WidgetAlign.Center,
                    imagePath = "",
                )
            }

            val startDate = runCatching { item.startDate }.getOrDefault(today)
            return DdayWidgetRenderState(
                titleText = item.title,
                dateText = MemoryBoxDates.dDayText(startDate, today),
                showTitle = item.isShowTitle,
                showDate = item.isShowDate,
                titleAlignment = item.titleAlignment,
                dateAlignment = item.dateAlignment,
                imagePath = item.imagePath,
            )
        }
    }
}
