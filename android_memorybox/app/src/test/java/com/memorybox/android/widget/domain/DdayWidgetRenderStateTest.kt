package com.memorybox.android.widget.domain

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DdayWidgetRenderStateTest {
    @Test
    fun selectedItemBuildsWidgetTextVisibilityAlignmentAndImagePath() {
        val item = DdayWidgetItem(
            id = "anniversary",
            title = "Anniversary",
            startDateIso = "2026-04-25",
            imagePath = "/private/widget/anniversary.jpg",
            isShowDate = false,
            dateAlignment = WidgetAlign.BottomRight,
            isShowTitle = true,
            titleAlignment = WidgetAlign.TopLeft,
        )

        val state = DdayWidgetRenderState.from(item, today = LocalDate.of(2026, 4, 27))

        assertEquals("Anniversary", state.titleText)
        assertEquals("3일", state.dateText)
        assertFalse(state.showDate)
        assertTrue(state.showTitle)
        assertEquals(WidgetAlign.BottomRight, state.dateAlignment)
        assertEquals(WidgetAlign.TopLeft, state.titleAlignment)
        assertEquals("/private/widget/anniversary.jpg", state.imagePath)
        assertFalse(state.useCombinedTextGroup)
    }

    @Test
    fun matchingTitleAndDateAlignmentUsesCombinedTextGroup() {
        val item = DdayWidgetItem(
            title = "Same spot",
            startDateIso = "2026-04-27",
            dateAlignment = WidgetAlign.BottomCenter,
            titleAlignment = WidgetAlign.BottomCenter,
        )

        val state = DdayWidgetRenderState.from(item, today = LocalDate.of(2026, 4, 27))

        assertTrue(state.showDate)
        assertTrue(state.showTitle)
        assertTrue(state.useCombinedTextGroup)
        assertEquals(WidgetAlign.BottomCenter, state.titleAlignment)
        assertEquals(WidgetAlign.BottomCenter, state.dateAlignment)
    }
}
