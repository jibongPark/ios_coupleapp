package com.memorybox.android.calendar.data

import kotlinx.serialization.Serializable

@Serializable
data class CalendarDto(
    val todos: List<TodoDto> = emptyList(),
    val schedules: List<ScheduleDto> = emptyList(),
    val diaries: List<DiaryDto> = emptyList(),
)

@Serializable
data class TodoDto(
    val id: String = "",
    val author: String = "",
    val title: String = "",
    val memo: String = "",
    val endDate: String,
    val isDone: Boolean = false,
    val color: Int = 0x0000FF,
    val shared: List<String> = emptyList(),
    val createdAt: String = "",
    val updatedAt: String = "",
)

@Serializable
data class ScheduleDto(
    val id: String = "",
    val author: String = "",
    val title: String = "",
    val startDate: String,
    val endDate: String,
    val memo: String = "",
    val color: Int = 0x0000FF,
    val shared: List<String> = emptyList(),
    val createdAt: String = "",
    val updatedAt: String = "",
)

@Serializable
data class DiaryDto(
    val id: String = "",
    val author: String = "",
    val date: String,
    val content: String = "",
    val shared: List<String> = emptyList(),
    val createdAt: String = "",
    val updatedAt: String = "",
)

@Serializable
data class CalendarOpDto(
    val id: String,
    val type: String,
    val method: String,
)
