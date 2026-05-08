package com.memorybox.android.calendar

import com.memorybox.android.calendar.data.CalendarDto
import com.memorybox.android.calendar.data.CalendarJsonStore
import com.memorybox.android.calendar.data.CalendarRepositoryImpl
import com.memorybox.android.calendar.data.CalendarServerTransport
import com.memorybox.android.calendar.data.CalendarSyncPayload
import com.memorybox.android.calendar.data.DiaryDto
import com.memorybox.android.calendar.data.ScheduleDto
import com.memorybox.android.calendar.data.TodoDto
import com.memorybox.android.calendar.domain.Diary
import com.memorybox.android.calendar.domain.Schedule
import com.memorybox.android.calendar.domain.Todo
import java.io.File
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CalendarRepositoryTest {
    private val fixedClock: Clock = Clock.fixed(Instant.parse("2026-04-27T01:02:03Z"), ZoneOffset.UTC)

    @Test
    fun persistsLocalUpdatesAcrossRepositoryInstancesAndGroupsVisibleGridDays() {
        val file = tempStoreFile()
        val firstRepository = repository(file, ids = mutableListOf("local_todo", "local_diary", "local_schedule"))

        val savedTodo = firstRepository.updateTodo(
            Todo(title = "Todo", endDate = LocalDate.of(2026, 4, 7))
        )
        val savedDiary = firstRepository.updateDiary(
            Diary(date = LocalDate.of(2026, 4, 7), content = "Diary")
        )
        val savedSchedule = firstRepository.updateSchedule(
            Schedule(
                title = "Trip",
                startDate = LocalDate.of(2026, 4, 6),
                endDate = LocalDate.of(2026, 4, 8),
            )
        )

        val secondRepository = repository(file)
        val visibleData = secondRepository.fetchVisibleGrid(LocalDate.of(2026, 4, 1))

        assertEquals(savedTodo.id, visibleData.todos.getValue("20260407").single().id)
        assertEquals(savedDiary.id, visibleData.diaries.getValue("20260407").id)
        assertEquals(savedSchedule.id, visibleData.schedules.getValue("20260406").single().id)
        assertEquals(savedSchedule.id, visibleData.schedules.getValue("20260407").single().id)
        assertEquals(savedSchedule.id, visibleData.schedules.getValue("20260408").single().id)
        assertFalse(visibleData.todos.containsKey("20260503"))
    }

    @Test
    fun deleteMethodsQueueServerDeletesButDropLocalOnlyRecords() {
        val repository = repository(
            tempStoreFile(),
            ids = mutableListOf("local_todo", "local_diary", "local_schedule"),
        )
        val localTodo = repository.updateTodo(Todo(title = "Local", endDate = LocalDate.of(2026, 4, 7)))
        repository.updateTodo(Todo(id = "server-todo", title = "Remote", endDate = LocalDate.of(2026, 4, 8)))
        repository.updateDiary(Diary(id = "server-diary", date = LocalDate.of(2026, 4, 9), content = "Diary"))
        repository.updateSchedule(
            Schedule(
                id = "server-schedule",
                title = "Schedule",
                startDate = LocalDate.of(2026, 4, 10),
                endDate = LocalDate.of(2026, 4, 11),
            )
        )

        repository.deleteTodo(localTodo.id)
        repository.deleteTodo("server-todo")
        repository.deleteDiary("server-diary")
        repository.deleteSchedule("server-schedule")

        val payload = repository.buildSyncPayload()

        assertEquals(
            listOf("server-todo:todo:delete", "server-diary:diary:delete", "server-schedule:schedule:delete"),
            payload.ops.map { "${it.id}:${it.type}:${it.method}" },
        )
        assertTrue(payload.todos.none { it.id == localTodo.id })
    }

    @Test
    fun buildSyncPayloadMatchesIosShapeAndStripsLocalIds() {
        val repository = repository(
            tempStoreFile(),
            ids = mutableListOf("local_todo", "local_diary", "local_schedule"),
        )

        repository.updateTodo(
            Todo(title = "Todo", memo = "Memo", endDate = LocalDate.of(2026, 4, 7), isDone = true, color = 0x123456)
        )
        repository.updateDiary(Diary(date = LocalDate.of(2026, 4, 7), content = "Diary"))
        repository.updateSchedule(
            Schedule(
                title = "Schedule",
                startDate = LocalDate.of(2026, 4, 7),
                endDate = LocalDate.of(2026, 4, 9),
                memo = "Schedule memo",
                color = 0x654321,
            )
        )

        val payload = repository.buildSyncPayload()

        assertEquals(emptyList<Any>(), payload.ops)
        assertEquals("", payload.todos.single().id)
        assertEquals("Todo", payload.todos.single().title)
        assertEquals("2026-04-07T00:00:00Z", payload.todos.single().endDate)
        assertEquals("", payload.diaries.single().id)
        assertEquals("2026-04-07T00:00:00Z", payload.diaries.single().date)
        assertEquals("", payload.schedules.single().id)
        assertEquals("2026-04-09T00:00:00Z", payload.schedules.single().endDate)
    }

    @Test
    fun syncServerSendsPayloadThroughTransportAndReplacesLocalRecordsOnSuccess() {
        val fakeTransport = FakeCalendarServerTransport(
            response = CalendarDto(
                todos = listOf(
                    TodoDto(id = "server-todo", title = "Synced Todo", endDate = "2026-04-07T00:00:00Z")
                ),
                schedules = listOf(
                    ScheduleDto(
                        id = "server-schedule",
                        title = "Synced Schedule",
                        startDate = "2026-04-07T00:00:00Z",
                        endDate = "2026-04-08T00:00:00Z",
                    )
                ),
                diaries = listOf(
                    DiaryDto(id = "server-diary", date = "2026-04-07T00:00:00Z", content = "Synced Diary")
                ),
            )
        )
        val repository = repository(
            tempStoreFile(),
            ids = mutableListOf("local_todo", "local_diary", "local_schedule"),
            transport = fakeTransport,
        )
        repository.updateTodo(Todo(title = "Local Todo", endDate = LocalDate.of(2026, 4, 7)))
        repository.updateDiary(Diary(date = LocalDate.of(2026, 4, 7), content = "Local Diary"))
        repository.updateSchedule(
            Schedule(
                title = "Local Schedule",
                startDate = LocalDate.of(2026, 4, 7),
                endDate = LocalDate.of(2026, 4, 8),
            )
        )

        assertTrue(repository.syncServer())

        val visibleData = repository.fetchVisibleGrid(LocalDate.of(2026, 4, 1))
        assertEquals(listOf(""), fakeTransport.lastPayload?.todos?.map { it.id })
        assertEquals("server-todo", visibleData.todos.getValue("20260407").single().id)
        assertEquals("server-diary", visibleData.diaries.getValue("20260407").id)
        assertEquals("server-schedule", visibleData.schedules.getValue("20260408").single().id)
        assertTrue(repository.buildSyncPayload().todos.isEmpty())
        assertTrue(repository.buildSyncPayload().diaries.isEmpty())
        assertTrue(repository.buildSyncPayload().schedules.isEmpty())
    }

    @Test
    fun corruptStoreReadQuarantinesRawFileBeforeReturningEmptySnapshot() {
        val directory = File(System.getProperty("java.io.tmpdir"), "calendar-corrupt-${UUID.randomUUID()}")
        directory.mkdirs()
        val file = File(directory, "calendar_store.json")
        file.writeText("{not-json")

        val snapshot = CalendarJsonStore(file).read()
        val quarantinedFiles = directory.listFiles { _, name ->
            name.startsWith("${file.name}.corrupt-")
        }.orEmpty()

        assertTrue(snapshot.todos.isEmpty())
        assertFalse(file.exists())
        assertEquals(1, quarantinedFiles.size)
        assertEquals("{not-json", quarantinedFiles.single().readText())
    }

    private fun repository(
        file: File,
        ids: MutableList<String> = mutableListOf("local_unused"),
        transport: CalendarServerTransport = FakeCalendarServerTransport(),
    ): CalendarRepositoryImpl {
        return CalendarRepositoryImpl(
            store = CalendarJsonStore(file),
            transport = transport,
            idProvider = { ids.removeAt(0) },
            clock = fixedClock,
        )
    }

    private fun tempStoreFile(): File {
        val file = File(System.getProperty("java.io.tmpdir"), "calendar-${UUID.randomUUID()}.json")
        file.deleteOnExit()
        return file
    }
}

private class FakeCalendarServerTransport(
    private val response: CalendarDto? = null,
) : CalendarServerTransport {
    var lastPayload: CalendarSyncPayload? = null

    override fun fetchCalendar(startDate: String, endDate: String, lastFetch: String): CalendarDto? = null

    override fun sync(payload: CalendarSyncPayload): CalendarDto? {
        lastPayload = payload
        return response
    }
}
