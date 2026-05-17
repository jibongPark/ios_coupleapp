package com.memorybox.android.widget.data

import com.memorybox.android.widget.domain.DdayWidgetItem
import com.memorybox.android.widget.domain.WidgetAlign
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DdayWidgetStoreTest {
    @Test
    fun upsertAddsSelectsAndUpdatesExistingItem() {
        val item = DdayWidgetItem(
            id = "first",
            title = "First day",
            startDateIso = "2026-04-01",
            imagePath = "/images/first.jpg",
            isShowDate = false,
            dateAlignment = WidgetAlign.BottomRight,
            isShowTitle = true,
            titleAlignment = WidgetAlign.TopLeft,
        )

        val inserted = DdayWidgetStore.upsert(DdayWidgetStore.State(), item)

        assertEquals(listOf(item), inserted.items)
        assertEquals("first", inserted.selectedId)

        val updatedItem = item.copy(
            title = "Updated first day",
            imagePath = "/images/updated.jpg",
            isShowDate = true,
            titleAlignment = WidgetAlign.CenterRight,
        )
        val updated = DdayWidgetStore.upsert(inserted, updatedItem)

        assertEquals(listOf(updatedItem), updated.items)
        assertEquals("first", updated.selectedId)
    }

    @Test
    fun removeSelectedItemSelectsFirstRemainingItem() {
        val first = DdayWidgetItem(id = "first", title = "First")
        val second = DdayWidgetItem(id = "second", title = "Second")
        val state = DdayWidgetStore.State(items = listOf(first, second), selectedId = "second")

        val removedSelected = DdayWidgetStore.remove(state, "second")

        assertEquals(listOf(first), removedSelected.items)
        assertEquals("first", removedSelected.selectedId)

        val empty = DdayWidgetStore.remove(removedSelected, "first")

        assertEquals(emptyList<DdayWidgetItem>(), empty.items)
        assertNull(empty.selectedId)
    }

    @Test
    fun selectOnlyChangesSelectionWhenItemExists() {
        val first = DdayWidgetItem(id = "first", title = "First")
        val second = DdayWidgetItem(id = "second", title = "Second")
        val state = DdayWidgetStore.State(items = listOf(first, second), selectedId = "first")

        val selected = DdayWidgetStore.select(state, "second")
        val unchanged = DdayWidgetStore.select(selected, "missing")

        assertEquals("second", selected.selectedId)
        assertEquals(second, DdayWidgetStore.selected(selected))
        assertEquals("second", unchanged.selectedId)
        assertEquals(second, DdayWidgetStore.selected(unchanged))
    }

    @Test
    fun itemJsonRoundTripPersistsImageAndDisplayOptions() {
        val item = DdayWidgetItem(
            id = "anniversary",
            title = "Anniversary",
            startDateIso = "2026-04-20",
            imagePath = "/private/widget/anniversary.jpg",
            isShowDate = false,
            dateAlignment = WidgetAlign.BottomCenter,
            isShowTitle = false,
            titleAlignment = WidgetAlign.TopRight,
        )

        val restored = DdayWidgetStore.decodeItems(DdayWidgetStore.encodeItems(listOf(item)))

        assertEquals(listOf(item), restored)
        assertEquals("/private/widget/anniversary.jpg", restored.single().imagePath)
        assertEquals(false, restored.single().isShowDate)
        assertEquals(WidgetAlign.BottomCenter, restored.single().dateAlignment)
        assertEquals(false, restored.single().isShowTitle)
        assertEquals(WidgetAlign.TopRight, restored.single().titleAlignment)
    }

    @Test
    fun upsertAppliesActiveSharedSpaceButSelectionRemainsLocal() {
        val item = DdayWidgetItem(id = "anniversary", title = "Anniversary")

        val state = DdayWidgetStore.upsert(DdayWidgetStore.State(), item, activeSharedSpaceId = "space-1")

        assertEquals("space-1", state.items.single().sharedSpaceId)
        assertEquals("anniversary", state.selectedId)
    }
}
