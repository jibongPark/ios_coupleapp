package com.memorybox.android.widget.data

import android.content.Context
import android.content.SharedPreferences
import com.memorybox.android.widget.domain.DdayWidgetItem
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

object DdayWidgetStore {
    private const val PREF_NAME = "memorybox_dday_widgets"
    private const val ITEMS_KEY = "items"
    private const val SELECTED_KEY = "selected"
    private const val ITEMS_CORRUPT_PREFIX = "items_corrupt_"
    private val json = Json { ignoreUnknownKeys = true }

    data class State(
        val items: List<DdayWidgetItem> = emptyList(),
        val selectedId: String? = null,
    )

    fun loadAll(context: Context): List<DdayWidgetItem> {
        return loadState(context).items
    }

    fun upsert(context: Context, item: DdayWidgetItem) {
        saveState(context, upsert(loadState(context), item))
    }

    fun remove(context: Context, id: String) {
        saveState(context, remove(loadState(context), id))
    }

    fun select(context: Context, id: String) {
        saveState(context, select(loadState(context), id))
    }

    fun selected(context: Context): DdayWidgetItem? {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val selectedId = prefs.getString(SELECTED_KEY, null)
        return selected(State(items = loadAll(context), selectedId = selectedId))
    }

    fun upsert(state: State, item: DdayWidgetItem): State {
        val existingIndex = state.items.indexOfFirst { it.id == item.id }
        val updatedItems = if (existingIndex >= 0) {
            state.items.map { existing -> if (existing.id == item.id) item else existing }
        } else {
            state.items + item
        }
        return State(items = updatedItems, selectedId = item.id)
    }

    fun remove(state: State, id: String): State {
        val updatedItems = state.items.filterNot { it.id == id }
        val selectedId = when {
            state.selectedId == id -> updatedItems.firstOrNull()?.id
            else -> normalizeSelectedId(updatedItems, state.selectedId)
        }
        return State(items = updatedItems, selectedId = selectedId)
    }

    fun select(state: State, id: String): State {
        return if (state.items.any { it.id == id }) {
            state.copy(selectedId = id)
        } else {
            state
        }
    }

    fun selected(state: State): DdayWidgetItem? {
        return state.items.firstOrNull { it.id == state.selectedId } ?: state.items.firstOrNull()
    }

    fun encodeItems(items: List<DdayWidgetItem>): String {
        return json.encodeToString(items)
    }

    fun decodeItems(raw: String?): List<DdayWidgetItem> {
        return decodeItemsOrNull(raw) ?: emptyList()
    }

    private fun loadState(context: Context): State {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val rawItems = prefs.getString(ITEMS_KEY, null)
        val items = decodeItemsOrNull(rawItems) ?: run {
            preserveCorruptItems(prefs, rawItems)
            emptyList()
        }
        return State(
            items = items,
            selectedId = normalizeSelectedId(items, prefs.getString(SELECTED_KEY, null)),
        )
    }

    private fun saveState(context: Context, state: State) {
        val editor = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(ITEMS_KEY, encodeItems(state.items))
        if (state.selectedId == null) {
            editor.remove(SELECTED_KEY)
        } else {
            editor.putString(SELECTED_KEY, state.selectedId)
        }
        editor.apply()
    }

    private fun normalizeSelectedId(items: List<DdayWidgetItem>, selectedId: String?): String? {
        return selectedId?.takeIf { id -> items.any { it.id == id } } ?: items.firstOrNull()?.id
    }

    private fun decodeItemsOrNull(raw: String?): List<DdayWidgetItem>? {
        if (raw == null) return emptyList()
        return runCatching {
            json.decodeFromString(ListSerializer(DdayWidgetItem.serializer()), raw)
        }.getOrNull()
    }

    private fun preserveCorruptItems(prefs: SharedPreferences, raw: String?) {
        if (raw.isNullOrBlank()) return
        prefs.edit()
            .putString("$ITEMS_CORRUPT_PREFIX${System.currentTimeMillis()}", raw)
            .remove(ITEMS_KEY)
            .remove(SELECTED_KEY)
            .apply()
    }
}
