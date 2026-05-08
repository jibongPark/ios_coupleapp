package com.memorybox.android.widget.ui

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.memorybox.android.core.date.MemoryBoxDates
import com.memorybox.android.widget.DdayWidgetProvider
import com.memorybox.android.widget.data.DdayImageFiles
import com.memorybox.android.widget.data.DdayWidgetStore
import com.memorybox.android.widget.domain.DdayWidgetItem
import com.memorybox.android.widget.domain.WidgetAlign
import java.time.LocalDate
import java.util.UUID

@Composable
fun DdayScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val items = remember { mutableStateListOf<DdayWidgetItem>().also { it += DdayWidgetStore.loadAll(context) } }
    var selectedId by remember { mutableStateOf(DdayWidgetStore.selected(context)?.id) }
    var editingId by remember { mutableStateOf<String?>(null) }
    var title by remember { mutableStateOf("") }
    var startDateIso by remember { mutableStateOf(LocalDate.now().toString()) }
    var imagePath by remember { mutableStateOf("") }
    var stagedImagePath by remember { mutableStateOf<String?>(null) }
    var imageError by remember { mutableStateOf<String?>(null) }
    var isShowDate by remember { mutableStateOf(true) }
    var isShowTitle by remember { mutableStateOf(true) }
    var dateAlignment by remember { mutableStateOf(WidgetAlign.Center) }
    var titleAlignment by remember { mutableStateOf(WidgetAlign.Center) }

    fun refreshWidgets() {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, DdayWidgetProvider::class.java))
        DdayWidgetProvider().onUpdate(context, manager, ids)
    }

    fun reloadItems() {
        items.clear()
        items += DdayWidgetStore.loadAll(context)
        selectedId = DdayWidgetStore.selected(context)?.id
    }

    fun discardStagedImage() {
        stagedImagePath?.let { filename ->
            DdayImageFiles.deleteByFilename(context, filename)
        }
        stagedImagePath = null
    }

    fun clearForm(discardStaged: Boolean = true) {
        if (discardStaged) {
            discardStagedImage()
        }
        editingId = null
        title = ""
        startDateIso = LocalDate.now().toString()
        imagePath = ""
        imageError = null
        isShowDate = true
        isShowTitle = true
        dateAlignment = WidgetAlign.Center
        titleAlignment = WidgetAlign.Center
    }

    fun loadForEdit(item: DdayWidgetItem) {
        discardStagedImage()
        editingId = item.id
        title = item.title
        startDateIso = item.startDateIso
        imagePath = item.imagePath
        imageError = null
        isShowDate = item.isShowDate
        isShowTitle = item.isShowTitle
        dateAlignment = item.dateAlignment
        titleAlignment = item.titleAlignment
    }

    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        runCatching { DdayImageFiles.copyUri(context, uri) }
            .onSuccess { filename ->
                discardStagedImage()
                imagePath = filename
                stagedImagePath = filename
                imageError = null
            }
            .onFailure {
                imageError = it.message ?: "이미지를 저장하지 못했습니다."
            }
    }

    val canSave = title.isNotBlank() && runCatching { LocalDate.parse(startDateIso) }.isSuccess

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("디데이 위젯", style = MaterialTheme.typography.titleLarge)
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("디데이 제목") },
        )
        OutlinedTextField(
            value = startDateIso,
            onValueChange = { startDateIso = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("처음 만난 날 yyyy-MM-dd") },
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedButton(
                modifier = Modifier.weight(1f),
                onClick = { imagePicker.launch("image/*") },
            ) {
                Text("사진 선택")
            }
            OutlinedButton(
                modifier = Modifier.weight(1f),
                enabled = imagePath.isNotBlank(),
                onClick = {
                    if (imagePath == stagedImagePath) {
                        discardStagedImage()
                    }
                    imagePath = ""
                    imageError = null
                },
            ) {
                Text("사진 삭제")
            }
        }
        if (imagePath.isNotBlank()) {
            Text("선택된 사진: $imagePath", style = MaterialTheme.typography.bodySmall)
        }
        imageError?.let {
            Text(it, color = MaterialTheme.colorScheme.error)
        }
        ToggleRow(
            label = "디데이 표시",
            checked = isShowDate,
            onCheckedChange = { isShowDate = it },
        )
        if (isShowDate) {
            AlignmentCycleButton(
                label = "디데이 위치",
                value = dateAlignment,
                onValueChange = { dateAlignment = it },
            )
        }
        ToggleRow(
            label = "제목 표시",
            checked = isShowTitle,
            onCheckedChange = { isShowTitle = it },
        )
        if (isShowTitle) {
            AlignmentCycleButton(
                label = "제목 위치",
                value = titleAlignment,
                onValueChange = { titleAlignment = it },
            )
        }
        Button(
            enabled = canSave,
            onClick = {
                val oldImagePath = editingId?.let { id ->
                    items.firstOrNull { it.id == id }?.imagePath
                }
                val item = DdayWidgetItem(
                    id = editingId ?: UUID.randomUUID().toString(),
                    title = title,
                    startDateIso = startDateIso,
                    imagePath = imagePath,
                    isShowDate = isShowDate,
                    dateAlignment = dateAlignment,
                    isShowTitle = isShowTitle,
                    titleAlignment = titleAlignment,
                )
                DdayWidgetStore.upsert(context, item)
                if (
                    oldImagePath != null &&
                    oldImagePath != imagePath &&
                    DdayImageFiles.isManagedFilename(oldImagePath)
                ) {
                    DdayImageFiles.deleteByFilename(context, oldImagePath)
                }
                stagedImagePath = null
                reloadItems()
                clearForm(discardStaged = false)
                refreshWidgets()
            },
        ) {
            Text(if (editingId == null) "저장" else "수정 저장")
        }
        if (editingId != null) {
            TextButton(onClick = { clearForm() }) {
                Text("수정 취소")
            }
        }

        if (items.isEmpty()) {
            Text("등록된 D-Day가 없습니다. 첫 기념일을 추가해보세요.", style = MaterialTheme.typography.bodyMedium)
        }

        items.forEach { item ->
            Card(Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    val selected = selectedId == item.id
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(item.title, style = MaterialTheme.typography.titleMedium)
                            Text(MemoryBoxDates.dDayText(item.startDate))
                            if (item.imagePath.isNotBlank()) {
                                Text(item.imagePath, style = MaterialTheme.typography.bodySmall)
                            }
                            Text(
                                "날짜 ${item.dateAlignment.displayName()} · 제목 ${item.titleAlignment.displayName()}",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                        Text(if (selected) "선택됨" else "미선택")
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        OutlinedButton(
                            modifier = Modifier.weight(1f),
                            enabled = !selected,
                            onClick = {
                                DdayWidgetStore.select(context, item.id)
                                reloadItems()
                                refreshWidgets()
                            },
                        ) {
                            Text("선택")
                        }
                        OutlinedButton(
                            modifier = Modifier.weight(1f),
                            onClick = { loadForEdit(item) },
                        ) {
                            Text("수정")
                        }
                        Button(
                            modifier = Modifier.weight(1f),
                            onClick = {
                                if (DdayImageFiles.isManagedFilename(item.imagePath)) {
                                    DdayImageFiles.deleteByFilename(context, item.imagePath)
                                }
                                DdayWidgetStore.remove(context, item.id)
                                reloadItems()
                                if (editingId == item.id) clearForm()
                                refreshWidgets()
                            },
                        ) {
                            Text("삭제")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ToggleRow(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label)
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun AlignmentCycleButton(
    label: String,
    value: WidgetAlign,
    onValueChange: (WidgetAlign) -> Unit,
) {
    OutlinedButton(
        modifier = Modifier.fillMaxWidth(),
        onClick = { onValueChange(value.next()) },
    ) {
        Text("$label: ${value.displayName()}")
    }
}

private fun WidgetAlign.next(): WidgetAlign {
    val values = WidgetAlign.values()
    return values[(ordinal + 1) % values.size]
}

private fun WidgetAlign.displayName(): String {
    return when (this) {
        WidgetAlign.TopLeft -> "상단 왼쪽"
        WidgetAlign.TopCenter -> "상단 중앙"
        WidgetAlign.TopRight -> "상단 오른쪽"
        WidgetAlign.CenterLeft -> "중앙 왼쪽"
        WidgetAlign.Center -> "중앙"
        WidgetAlign.CenterRight -> "중앙 오른쪽"
        WidgetAlign.BottomLeft -> "하단 왼쪽"
        WidgetAlign.BottomCenter -> "하단 중앙"
        WidgetAlign.BottomRight -> "하단 오른쪽"
    }
}
