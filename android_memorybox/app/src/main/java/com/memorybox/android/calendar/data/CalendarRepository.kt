package com.memorybox.android.calendar.data

import android.content.Context
import com.memorybox.android.calendar.domain.CalendarDatas
import com.memorybox.android.calendar.domain.CalendarGrid
import com.memorybox.android.calendar.domain.Diary
import com.memorybox.android.calendar.domain.Schedule
import com.memorybox.android.calendar.domain.Todo
import com.memorybox.android.calendar.domain.localId
import com.memorybox.android.core.network.ApiResponse
import com.memorybox.android.core.network.MemoryBoxEndpoints
import com.memorybox.android.core.network.MemoryBoxHttpClient
import com.memorybox.android.core.network.MemoryBoxHttpMethod
import com.memorybox.android.core.network.MemoryBoxHttpRequest
import java.io.File
import java.net.URLEncoder
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

interface CalendarRepository {
    fun fetchVisibleGrid(monthDate: LocalDate, refreshFromServer: Boolean = false, lastFetch: String = ""): CalendarDatas
    fun fetch(monthDate: LocalDate): CalendarDatas = fetchVisibleGrid(monthDate)
    fun updateTodo(todo: Todo): Todo
    fun updateDiary(diary: Diary): Diary
    fun updateSchedule(schedule: Schedule): Schedule
    fun deleteTodo(id: String)
    fun deleteDiary(id: String)
    fun deleteSchedule(id: String)
    fun buildSyncPayload(changedAfter: Instant? = null): CalendarSyncPayload
    fun syncServer(changedAfter: Instant? = null): Boolean
}

// Server transport is injected so sync payload behavior can be tested without real HTTP.
interface CalendarServerTransport {
    fun fetchCalendar(startDate: String, endDate: String, lastFetch: String): CalendarDto?
    fun sync(payload: CalendarSyncPayload): CalendarDto?
}

object NoopCalendarServerTransport : CalendarServerTransport {
    override fun fetchCalendar(startDate: String, endDate: String, lastFetch: String): CalendarDto? = null
    override fun sync(payload: CalendarSyncPayload): CalendarDto? = null
}

class NetworkCalendarServerTransport(
    private val client: MemoryBoxHttpClient,
    private val accessTokenProvider: () -> String?,
    private val refreshAccessToken: (() -> String?)? = null,
    private val json: Json = Json { ignoreUnknownKeys = true },
) : CalendarServerTransport {
    override fun fetchCalendar(startDate: String, endDate: String, lastFetch: String): CalendarDto? {
        val path = buildString {
            append(MemoryBoxEndpoints.Calendar.calendar)
            append("?startDate=")
            append(startDate.urlEncode())
            append("&endDate=")
            append(endDate.urlEncode())
            append("&lastFetch=")
            append(lastFetch.urlEncode())
        }
        val response = executeWithRefresh(
            MemoryBoxHttpRequest(
                method = MemoryBoxHttpMethod.Get,
                path = path,
            ),
        )
        if (!response.isSuccessful) return null
        return runCatching {
            json.decodeFromString<ApiResponse<CalendarDto>>(response.body).data
        }.getOrNull()
    }

    override fun sync(payload: CalendarSyncPayload): CalendarDto? {
        val response = executeWithRefresh(
            MemoryBoxHttpRequest(
                method = MemoryBoxHttpMethod.Post,
                path = MemoryBoxEndpoints.Calendar.sync,
                body = json.encodeToString(payload),
            ),
        )
        if (!response.isSuccessful) return null
        return runCatching {
            json.decodeFromString<ApiResponse<CalendarDto>>(response.body).data
        }.getOrNull()
    }

    private fun executeWithRefresh(request: MemoryBoxHttpRequest) =
        client.execute(request.copy(bearerToken = accessTokenProvider())).let { response ->
            if (!response.isUnauthorized) {
                response
            } else {
                val refreshedToken = refreshAccessToken?.invoke()
                if (refreshedToken.isNullOrBlank()) {
                    response
                } else {
                    client.execute(request.copy(bearerToken = refreshedToken))
                }
            }
        }
}

// App-private JSON keeps calendar data local-first while leaving a narrow replacement point for Room later.
class CalendarJsonStore(
    private val file: File,
    private val json: Json = Json {
        encodeDefaults = true
        ignoreUnknownKeys = true
        prettyPrint = true
    },
) {
    @Synchronized
    fun read(): CalendarStoreSnapshot {
        if (!file.exists()) return CalendarStoreSnapshot()

        return runCatching {
            json.decodeFromString<CalendarStoreSnapshot>(file.readText())
        }.getOrElse {
            quarantineCorruptFile()
            CalendarStoreSnapshot()
        }
    }

    @Synchronized
    fun write(snapshot: CalendarStoreSnapshot) {
        file.parentFile?.mkdirs()
        file.writeText(json.encodeToString(snapshot))
    }

    companion object {
        fun appPrivate(context: Context): CalendarJsonStore {
            return CalendarJsonStore(File(context.filesDir, "calendar/calendar_store.json"))
        }
    }

    private fun quarantineCorruptFile() {
        val parent = file.parentFile ?: return
        if (!file.exists()) return

        runCatching {
            val quarantine = File(parent, "${file.name}.corrupt-${System.currentTimeMillis()}")
            file.copyTo(quarantine, overwrite = true)
            file.delete()
        }
    }
}

class CalendarRepositoryImpl(
    private val store: CalendarJsonStore,
    private val transport: CalendarServerTransport = NoopCalendarServerTransport,
    private val idProvider: () -> String = ::localId,
    private val clock: Clock = Clock.systemUTC(),
    private val activeSharedSpaceIdProvider: () -> String? = { null },
) : CalendarRepository {
    override fun fetchVisibleGrid(
        monthDate: LocalDate,
        refreshFromServer: Boolean,
        lastFetch: String,
    ): CalendarDatas {
        val visibleDates = CalendarGrid.visibleDates(monthDate)

        if (refreshFromServer && visibleDates.isNotEmpty()) {
            val startDate = visibleDates.first().toServerDate()
            val endDate = visibleDates.last().plusDays(1).toServerDate()
            transport.fetchCalendar(startDate, endDate, lastFetch)?.let { mergeServerData(it) }
        }

        return groupVisibleDays(store.read(), visibleDates)
    }

    override fun updateTodo(todo: Todo): Todo {
        val now = nowString()
        val id = todo.id.ifBlank(idProvider)
        val sharedSpaceId = todo.sharedSpaceId ?: activeSharedSpaceIdProvider()?.takeIf { it.isNotBlank() }
        val shared = todo.shared.ifEmpty { sharedSpaceId?.let(::listOf).orEmpty() }
        val stored = StoredTodo(
            id = id,
            title = todo.title,
            memo = todo.memo,
            endDate = todo.endDate.toServerDate(),
            isDone = todo.isDone,
            color = todo.color,
            shared = shared,
            sharedSpaceId = sharedSpaceId,
            createdAt = existingTodo(id)?.createdAt ?: now,
            updatedAt = now,
            pendingSync = true,
        )
        store.write(store.read().replaceTodo(stored))
        return todo.copy(id = id, shared = shared, sharedSpaceId = sharedSpaceId)
    }

    override fun updateDiary(diary: Diary): Diary {
        val now = nowString()
        val id = diary.id.ifBlank(idProvider)
        val sharedSpaceId = diary.sharedSpaceId ?: activeSharedSpaceIdProvider()?.takeIf { it.isNotBlank() }
        val shared = diary.shared.ifEmpty { sharedSpaceId?.let(::listOf).orEmpty() }
        val stored = StoredDiary(
            id = id,
            date = diary.date.toServerDate(),
            content = diary.content,
            shared = shared,
            sharedSpaceId = sharedSpaceId,
            createdAt = existingDiary(id)?.createdAt ?: now,
            updatedAt = now,
            pendingSync = true,
        )
        store.write(store.read().replaceDiary(stored))
        return diary.copy(id = id, shared = shared, sharedSpaceId = sharedSpaceId)
    }

    override fun updateSchedule(schedule: Schedule): Schedule {
        val now = nowString()
        val id = schedule.id.ifBlank(idProvider)
        val sharedSpaceId = schedule.sharedSpaceId ?: activeSharedSpaceIdProvider()?.takeIf { it.isNotBlank() }
        val shared = schedule.shared.ifEmpty { sharedSpaceId?.let(::listOf).orEmpty() }
        val stored = StoredSchedule(
            id = id,
            title = schedule.title,
            startDate = schedule.startDate.toServerDate(),
            endDate = schedule.endDate.toServerDate(),
            memo = schedule.memo,
            color = schedule.color,
            shared = shared,
            sharedSpaceId = sharedSpaceId,
            createdAt = existingSchedule(id)?.createdAt ?: now,
            updatedAt = now,
            pendingSync = true,
        )
        store.write(store.read().replaceSchedule(stored))
        return schedule.copy(id = id, shared = shared, sharedSpaceId = sharedSpaceId)
    }

    override fun deleteTodo(id: String) {
        deleteRecord(id = id, type = CalendarItemType.Todo)
    }

    override fun deleteDiary(id: String) {
        deleteRecord(id = id, type = CalendarItemType.Diary)
    }

    override fun deleteSchedule(id: String) {
        deleteRecord(id = id, type = CalendarItemType.Schedule)
    }

    override fun buildSyncPayload(changedAfter: Instant?): CalendarSyncPayload {
        val snapshot = store.read()

        return CalendarSyncPayload(
            ops = snapshot.ops,
            todos = snapshot.todos
                .filter { it.shouldSync(changedAfter) }
                .map { it.toPayload() },
            schedules = snapshot.schedules
                .filter { it.shouldSync(changedAfter) }
                .map { it.toPayload() },
            diaries = snapshot.diaries
                .filter { it.shouldSync(changedAfter) }
                .map { it.toPayload() },
        )
    }

    override fun syncServer(changedAfter: Instant?): Boolean {
        val beforeSync = store.read()
        val payload = buildSyncPayload(changedAfter)
        val response = transport.sync(payload) ?: return false

        val syncedTodoIds = beforeSync.todos.filter { it.shouldSync(changedAfter) }.map { it.id }.toSet()
        val syncedScheduleIds = beforeSync.schedules.filter { it.shouldSync(changedAfter) }.map { it.id }.toSet()
        val syncedDiaryIds = beforeSync.diaries.filter { it.shouldSync(changedAfter) }.map { it.id }.toSet()

        val localPrefix = "local_"
        val cleanSnapshot = beforeSync.copy(
            ops = emptyList(),
            todos = beforeSync.todos
                .filterNot { it.id.startsWith(localPrefix) && it.id in syncedTodoIds }
                .map { if (it.id in syncedTodoIds) it.copy(pendingSync = false) else it },
            schedules = beforeSync.schedules
                .filterNot { it.id.startsWith(localPrefix) && it.id in syncedScheduleIds }
                .map { if (it.id in syncedScheduleIds) it.copy(pendingSync = false) else it },
            diaries = beforeSync.diaries
                .filterNot { it.id.startsWith(localPrefix) && it.id in syncedDiaryIds }
                .map { if (it.id in syncedDiaryIds) it.copy(pendingSync = false) else it },
        )

        store.write(mergeServerData(cleanSnapshot, response))
        return true
    }

    private fun deleteRecord(id: String, type: CalendarItemType) {
        val snapshot = store.read()
        val withoutRecord = when (type) {
            CalendarItemType.Todo -> snapshot.copy(todos = snapshot.todos.filterNot { it.id == id })
            CalendarItemType.Diary -> snapshot.copy(diaries = snapshot.diaries.filterNot { it.id == id })
            CalendarItemType.Schedule -> snapshot.copy(schedules = snapshot.schedules.filterNot { it.id == id })
        }

        val nextSnapshot = if (id.startsWith("local_")) {
            withoutRecord
        } else {
            withoutRecord.queueDelete(id = id, type = type.wireName)
        }

        store.write(nextSnapshot)
    }

    private fun groupVisibleDays(snapshot: CalendarStoreSnapshot, visibleDates: List<LocalDate>): CalendarDatas {
        val visibleKeys = visibleDates.map(CalendarGrid::dayKey).toSet()

        val todos = snapshot.todos
            .map { it.toDomain() }
            .filter { CalendarGrid.dayKey(it.endDate) in visibleKeys }
            .groupBy { CalendarGrid.dayKey(it.endDate) }

        val diaries = snapshot.diaries
            .map { it.toDomain() }
            .filter { CalendarGrid.dayKey(it.date) in visibleKeys }
            .associateBy { CalendarGrid.dayKey(it.date) }

        val schedules = buildMap<String, MutableList<Schedule>> {
            snapshot.schedules.map { it.toDomain() }.forEach { schedule ->
                CalendarGrid.inclusiveDayKeys(schedule.startDate, schedule.endDate)
                    .filter { it in visibleKeys }
                    .forEach { key ->
                        getOrPut(key) { mutableListOf() } += schedule
                    }
            }
        }

        return CalendarDatas(
            todos = todos,
            diaries = diaries,
            schedules = schedules,
        )
    }

    private fun mergeServerData(dto: CalendarDto) {
        store.write(mergeServerData(store.read(), dto))
    }

    private fun mergeServerData(snapshot: CalendarStoreSnapshot, dto: CalendarDto): CalendarStoreSnapshot {
        val now = nowString()
        val deletedTodoIds = snapshot.deletedIds(CalendarItemType.Todo)
        val deletedScheduleIds = snapshot.deletedIds(CalendarItemType.Schedule)
        val deletedDiaryIds = snapshot.deletedIds(CalendarItemType.Diary)
        return snapshot.copy(
            todos = mergeById(
                existing = snapshot.todos,
                incoming = dto.todos.map { it.toStored(now) }.filterNot { it.id in deletedTodoIds },
            ),
            schedules = mergeById(
                existing = snapshot.schedules,
                incoming = dto.schedules.map { it.toStored(now) }.filterNot { it.id in deletedScheduleIds },
            ),
            diaries = mergeById(
                existing = snapshot.diaries,
                incoming = dto.diaries.map { it.toStored(now) }.filterNot { it.id in deletedDiaryIds },
            ),
        )
    }

    private fun nowString(): String = clock.instant().toString()

    private fun existingTodo(id: String): StoredTodo? = store.read().todos.firstOrNull { it.id == id }
    private fun existingDiary(id: String): StoredDiary? = store.read().diaries.firstOrNull { it.id == id }
    private fun existingSchedule(id: String): StoredSchedule? = store.read().schedules.firstOrNull { it.id == id }
}

@Serializable
data class CalendarSyncPayload(
    val ops: List<CalendarOpDto> = emptyList(),
    val todos: List<CalendarTodoPayload> = emptyList(),
    val schedules: List<CalendarSchedulePayload> = emptyList(),
    val diaries: List<CalendarDiaryPayload> = emptyList(),
)

@Serializable
data class CalendarTodoPayload(
    val id: String,
    val title: String,
    val isDone: Boolean,
    val endDate: String,
    val memo: String,
    val color: Int,
    val shared: List<String>,
    val sharedSpaceId: String? = null,
)

@Serializable
data class CalendarSchedulePayload(
    val id: String,
    val title: String,
    val startDate: String,
    val endDate: String,
    val memo: String,
    val color: Int,
    val shared: List<String>,
    val sharedSpaceId: String? = null,
)

@Serializable
data class CalendarDiaryPayload(
    val id: String,
    val date: String,
    val content: String,
    val shared: List<String>,
    val sharedSpaceId: String? = null,
)

@Serializable
data class CalendarStoreSnapshot(
    val todos: List<StoredTodo> = emptyList(),
    val schedules: List<StoredSchedule> = emptyList(),
    val diaries: List<StoredDiary> = emptyList(),
    val ops: List<CalendarOpDto> = emptyList(),
)

@Serializable
data class StoredTodo(
    val id: String,
    val title: String,
    val memo: String,
    val endDate: String,
    val isDone: Boolean,
    val color: Int,
    val shared: List<String>,
    val sharedSpaceId: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val pendingSync: Boolean = false,
)

@Serializable
data class StoredSchedule(
    val id: String,
    val title: String,
    val startDate: String,
    val endDate: String,
    val memo: String,
    val color: Int,
    val shared: List<String>,
    val sharedSpaceId: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val pendingSync: Boolean = false,
)

@Serializable
data class StoredDiary(
    val id: String,
    val date: String,
    val content: String,
    val shared: List<String>,
    val sharedSpaceId: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val pendingSync: Boolean = false,
)

private enum class CalendarItemType(val wireName: String) {
    Todo("todo"),
    Diary("diary"),
    Schedule("schedule"),
}

private fun StoredTodo.toDomain(): Todo {
    return Todo(
        id = id,
        title = title,
        memo = memo,
        endDate = endDate.toLocalDateFromServer(),
        isDone = isDone,
        color = color,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
    )
}

private fun StoredSchedule.toDomain(): Schedule {
    return Schedule(
        id = id,
        title = title,
        startDate = startDate.toLocalDateFromServer(),
        endDate = endDate.toLocalDateFromServer(),
        memo = memo,
        color = color,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
    )
}

private fun StoredDiary.toDomain(): Diary {
    return Diary(
        id = id,
        date = date.toLocalDateFromServer(),
        content = content,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
    )
}

private fun TodoDto.toStored(now: String): StoredTodo {
    return StoredTodo(
        id = id,
        title = title,
        memo = memo,
        endDate = endDate.toLocalDateFromServer().toServerDate(),
        isDone = isDone,
        color = color,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
        createdAt = createdAt.ifBlank { now },
        updatedAt = updatedAt.ifBlank { now },
        pendingSync = false,
    )
}

private fun ScheduleDto.toStored(now: String): StoredSchedule {
    return StoredSchedule(
        id = id,
        title = title,
        startDate = startDate.toLocalDateFromServer().toServerDate(),
        endDate = endDate.toLocalDateFromServer().toServerDate(),
        memo = memo,
        color = color,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
        createdAt = createdAt.ifBlank { now },
        updatedAt = updatedAt.ifBlank { now },
        pendingSync = false,
    )
}

private fun DiaryDto.toStored(now: String): StoredDiary {
    return StoredDiary(
        id = id,
        date = date.toLocalDateFromServer().toServerDate(),
        content = content,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
        createdAt = createdAt.ifBlank { now },
        updatedAt = updatedAt.ifBlank { now },
        pendingSync = false,
    )
}

private fun StoredTodo.toPayload(): CalendarTodoPayload {
    return CalendarTodoPayload(
        id = syncPayloadId(),
        title = title,
        isDone = isDone,
        endDate = endDate,
        memo = memo,
        color = color,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
    )
}

private fun StoredSchedule.toPayload(): CalendarSchedulePayload {
    return CalendarSchedulePayload(
        id = syncPayloadId(),
        title = title,
        startDate = startDate,
        endDate = endDate,
        memo = memo,
        color = color,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
    )
}

private fun StoredDiary.toPayload(): CalendarDiaryPayload {
    return CalendarDiaryPayload(
        id = syncPayloadId(),
        date = date,
        content = content,
        shared = shared,
        sharedSpaceId = sharedSpaceId,
    )
}

private fun CalendarStoreSnapshot.replaceTodo(todo: StoredTodo): CalendarStoreSnapshot {
    return copy(todos = todos.filterNot { it.id == todo.id } + todo)
}

private fun CalendarStoreSnapshot.replaceDiary(diary: StoredDiary): CalendarStoreSnapshot {
    return copy(diaries = diaries.filterNot { it.id == diary.id } + diary)
}

private fun CalendarStoreSnapshot.replaceSchedule(schedule: StoredSchedule): CalendarStoreSnapshot {
    return copy(schedules = schedules.filterNot { it.id == schedule.id } + schedule)
}

private fun CalendarStoreSnapshot.queueDelete(id: String, type: String): CalendarStoreSnapshot {
    val op = CalendarOpDto(id = id, type = type, method = "delete")
    return copy(ops = ops.filterNot { it.id == id && it.type == type && it.method == "delete" } + op)
}

private fun StoredTodo.shouldSync(changedAfter: Instant?): Boolean = shouldSyncRecord(changedAfter)
private fun StoredSchedule.shouldSync(changedAfter: Instant?): Boolean = shouldSyncRecord(changedAfter)
private fun StoredDiary.shouldSync(changedAfter: Instant?): Boolean = shouldSyncRecord(changedAfter)

private fun StoredTodo.shouldSyncRecord(changedAfter: Instant?): Boolean {
    return pendingSync || id.startsWith("local_") || updatedAfter(changedAfter)
}

private fun StoredSchedule.shouldSyncRecord(changedAfter: Instant?): Boolean {
    return pendingSync || id.startsWith("local_") || updatedAfter(changedAfter)
}

private fun StoredDiary.shouldSyncRecord(changedAfter: Instant?): Boolean {
    return pendingSync || id.startsWith("local_") || updatedAfter(changedAfter)
}

private fun StoredTodo.updatedAfter(changedAfter: Instant?): Boolean {
    return changedAfter?.let { updatedAt.toInstantOrEpoch().isAfter(it) } ?: false
}

private fun StoredSchedule.updatedAfter(changedAfter: Instant?): Boolean {
    return changedAfter?.let { updatedAt.toInstantOrEpoch().isAfter(it) } ?: false
}

private fun StoredDiary.updatedAfter(changedAfter: Instant?): Boolean {
    return changedAfter?.let { updatedAt.toInstantOrEpoch().isAfter(it) } ?: false
}

private fun StoredTodo.syncPayloadId(): String = id.takeUnless { it.startsWith("local_") }.orEmpty()
private fun StoredSchedule.syncPayloadId(): String = id.takeUnless { it.startsWith("local_") }.orEmpty()
private fun StoredDiary.syncPayloadId(): String = id.takeUnless { it.startsWith("local_") }.orEmpty()

private fun LocalDate.toServerDate(): String {
    return atStartOfDay(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT)
}

private fun String.toLocalDateFromServer(): LocalDate {
    return runCatching { OffsetDateTime.parse(this).toLocalDate() }
        .getOrElse {
            runCatching { Instant.parse(this).atZone(ZoneOffset.UTC).toLocalDate() }
                .getOrElse { LocalDate.parse(this, DateTimeFormatter.ISO_LOCAL_DATE) }
        }
}

private fun String.toInstantOrEpoch(): Instant {
    return runCatching { Instant.parse(this) }.getOrDefault(Instant.EPOCH)
}

private fun String.urlEncode(): String =
    URLEncoder.encode(this, Charsets.UTF_8.name())

private fun CalendarStoreSnapshot.deletedIds(type: CalendarItemType): Set<String> {
    return ops
        .filter { it.type == type.wireName && it.method == "delete" }
        .map { it.id }
        .toSet()
}

private fun <T> mergeById(existing: List<T>, incoming: List<T>): List<T> where T : Any {
    val idReader: (T) -> String = { item ->
        when (item) {
            is StoredTodo -> item.id
            is StoredSchedule -> item.id
            is StoredDiary -> item.id
            else -> ""
        }
    }
    val merged = existing.associateBy(idReader).toMutableMap()
    incoming.filter { idReader(it).isNotBlank() }.forEach { incomingItem ->
        val id = idReader(incomingItem)
        val current = merged[id]
        if (current == null || !current.hasPendingSync()) {
            merged[id] = incomingItem
        }
    }
    return merged.values.toList()
}

private fun Any.hasPendingSync(): Boolean {
    return when (this) {
        is StoredTodo -> pendingSync
        is StoredSchedule -> pendingSync
        is StoredDiary -> pendingSync
        else -> false
    }
}
