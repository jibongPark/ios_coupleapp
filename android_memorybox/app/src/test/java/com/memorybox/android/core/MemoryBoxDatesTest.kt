package com.memorybox.android.core

import com.memorybox.android.core.date.MemoryBoxDates
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class MemoryBoxDatesTest {
    @Test
    fun dDayTextCountsTodayAsDayOne() {
        val today = LocalDate.of(2026, 4, 27)

        assertEquals("1일", MemoryBoxDates.dDayText(today, today))
    }

    @Test
    fun dDayTextCountsPastDatesInclusively() {
        val today = LocalDate.of(2026, 4, 27)
        val firstDate = LocalDate.of(2026, 4, 25)

        assertEquals("3일", MemoryBoxDates.dDayText(firstDate, today))
    }

    @Test
    fun dDayTextUsesIosFutureWording() {
        val today = LocalDate.of(2026, 4, 27)
        val futureDate = LocalDate.of(2026, 5, 2)

        assertEquals("5일 전", MemoryBoxDates.dDayText(futureDate, today))
    }
}
