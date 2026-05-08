package com.memorybox.android.calendar.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.memorybox.android.calendar.data.CalendarJsonStore
import com.memorybox.android.calendar.data.CalendarRepository
import com.memorybox.android.calendar.data.CalendarRepositoryImpl
import com.memorybox.android.calendar.domain.CalendarDatas
import com.memorybox.android.calendar.domain.CalendarGrid
import com.memorybox.android.calendar.domain.Diary
import com.memorybox.android.calendar.domain.Schedule
import com.memorybox.android.calendar.domain.Todo
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private data class CalendarTextItem(
    val type: String,
    val title: String,
)

@Composable
fun CalendarScreen(
    modifier: Modifier = Modifier,
    repository: CalendarRepository? = null,
    refreshFromServer: Boolean = false,
    refreshKey: Int = 0,
) {
    val appContext = LocalContext.current.applicationContext
    val defaultRepository = remember(appContext) {
        CalendarRepositoryImpl(CalendarJsonStore.appPrivate(appContext))
    }
    val calendarRepository = repository ?: defaultRepository
    var selectedMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }
    var title by remember { mutableStateOf("") }
    var calendarData by remember { mutableStateOf(CalendarDatas()) }
    val visibleDates = CalendarGrid.visibleDates(selectedMonth.atDay(1))
    val selectedKey = CalendarGrid.dayKey(selectedDate)

    fun reloadVisibleDataFromLocal() {
        calendarData = calendarRepository.fetchVisibleGrid(selectedMonth.atDay(1))
    }

    LaunchedEffect(calendarRepository, selectedMonth, refreshFromServer, refreshKey) {
        calendarData = withContext(Dispatchers.IO) {
            calendarRepository.fetchVisibleGrid(
                monthDate = selectedMonth.atDay(1),
                refreshFromServer = refreshFromServer,
            )
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Button(onClick = { selectedMonth = selectedMonth.minusMonths(1) }) {
                Text("<")
            }
            Text(
                selectedMonth.format(DateTimeFormatter.ofPattern("yyyy.MM")),
                style = MaterialTheme.typography.titleLarge,
            )
            Button(onClick = { selectedMonth = selectedMonth.plusMonths(1) }) {
                Text(">")
            }
        }

        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.weight(1f),
        ) {
            items(visibleDates) { date ->
                val isSelected = date == selectedDate
                val isCurrentMonth = date.month == selectedMonth.month
                Box(
                    modifier = Modifier
                        .padding(2.dp)
                        .background(if (isSelected) Color.LightGray else Color.Transparent)
                        .clickable { selectedDate = date }
                        .padding(6.dp),
                ) {
                    Column {
                        Text(
                            text = date.dayOfMonth.toString(),
                            color = if (isCurrentMonth) Color.Black else Color.Gray,
                        )
                        calendarData.textItemsForDay(CalendarGrid.dayKey(date)).take(2).forEach { item ->
                            Text(
                                text = item.title,
                                style = MaterialTheme.typography.labelSmall,
                                maxLines = 1,
                            )
                        }
                    }
                }
            }
        }

        Surface(tonalElevation = 2.dp) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text("${selectedDate.dayOfMonth}. ${selectedDate.dayOfWeek}", style = MaterialTheme.typography.titleMedium)
                calendarData.textItemsForDay(selectedKey).forEach { item ->
                    Text("${item.type}  ${item.title}")
                }
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("제목 또는 메모") },
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("일정", "할 일", "일기").forEach { type ->
                        Button(
                            enabled = title.isNotBlank(),
                            onClick = {
                                when (type) {
                                    "일정" -> calendarRepository.updateSchedule(
                                        Schedule(title = title, startDate = selectedDate, endDate = selectedDate)
                                    )
                                    "할 일" -> calendarRepository.updateTodo(
                                        Todo(title = title, endDate = selectedDate)
                                    )
                                    "일기" -> calendarRepository.updateDiary(
                                        Diary(date = selectedDate, content = title)
                                    )
                                }
                                title = ""
                                reloadVisibleDataFromLocal()
                            },
                        ) {
                            Text(type)
                        }
                    }
                }
            }
        }
    }
}

private fun CalendarDatas.textItemsForDay(dayKey: String): List<CalendarTextItem> {
    val scheduleItems = schedules[dayKey].orEmpty().map { CalendarTextItem("일정", it.title) }
    val todoItems = todos[dayKey].orEmpty().map { CalendarTextItem("할 일", it.title) }
    val diaryItems = listOfNotNull(diaries[dayKey]?.let { CalendarTextItem("일기", it.content) })

    return scheduleItems + todoItems + diaryItems
}
