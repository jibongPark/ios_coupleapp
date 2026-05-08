package com.memorybox.android.calendar

import com.memorybox.android.calendar.domain.CalendarGrid
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CalendarGridTest {
    @Test
    fun visibleGridStartsOnSundayAndCoversFullWeeks() {
        val grid = CalendarGrid.visibleDates(LocalDate.of(2026, 4, 1))

        assertEquals(LocalDate.of(2026, 3, 29), grid.first())
        assertEquals(LocalDate.of(2026, 5, 2), grid.last())
        assertEquals(35, grid.size)
        assertEquals(0, grid.size % 7)
    }

    @Test
    fun dayKeyMatchesIosCalendarKeyShape() {
        assertEquals("20260407", CalendarGrid.dayKey(LocalDate.of(2026, 4, 7)))
    }

    @Test
    fun multiDayScheduleExpandsAllInclusiveDates() {
        val keys = CalendarGrid.inclusiveDayKeys(
            LocalDate.of(2026, 4, 29),
            LocalDate.of(2026, 5, 1)
        )

        assertEquals(listOf("20260429", "20260430", "20260501"), keys)
        assertTrue(keys.all { it.length == 8 })
    }
}
