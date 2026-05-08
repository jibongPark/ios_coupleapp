package com.memorybox.android.calendar.domain

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID

data class CalendarDatas(
    val todos: Map<String, List<Todo>> = emptyMap(),
    val diaries: Map<String, Diary> = emptyMap(),
    val schedules: Map<String, List<Schedule>> = emptyMap(),
)

data class Todo(
    val id: String = "",
    val title: String = "",
    val memo: String = "",
    val endDate: LocalDate = LocalDate.now(),
    val isDone: Boolean = false,
    val color: Int = 0x0000FF,
    val shared: List<String> = emptyList(),
)

data class Schedule(
    val id: String = "",
    val title: String = "",
    val startDate: LocalDate = LocalDate.now(),
    val endDate: LocalDate = LocalDate.now(),
    val memo: String = "",
    val color: Int = 0x0000FF,
    val shared: List<String> = emptyList(),
)

data class Diary(
    val id: String = "",
    val date: LocalDate = LocalDate.now(),
    val content: String = "",
    val shared: List<String> = emptyList(),
)

data class CalendarOp(
    val id: String,
    val type: String,
    val method: String,
)

fun localId(): String = "local_${UUID.randomUUID()}"

object CalendarGrid {
    private val dayKeyFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyyMMdd")

    fun visibleDates(monthDate: LocalDate): List<LocalDate> {
        val firstOfMonth = monthDate.withDayOfMonth(1)
        val prefixDays = firstOfMonth.dayOfWeek.value % 7
        val totalSlots = ((prefixDays + monthDate.lengthOfMonth() + 6) / 7) * 7
        val gridStart = firstOfMonth.minusDays(prefixDays.toLong())

        return List(totalSlots) { offset ->
            gridStart.plusDays(offset.toLong())
        }
    }

    fun dayKey(date: LocalDate): String = date.format(dayKeyFormatter)

    fun inclusiveDayKeys(startDate: LocalDate, endDate: LocalDate): List<String> {
        val keys = mutableListOf<String>()
        var currentDate = startDate

        while (!currentDate.isAfter(endDate)) {
            keys += dayKey(currentDate)
            currentDate = currentDate.plusDays(1)
        }

        return keys
    }
}
