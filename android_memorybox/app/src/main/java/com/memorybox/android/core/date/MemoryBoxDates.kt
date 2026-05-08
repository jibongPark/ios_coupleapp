package com.memorybox.android.core.date

import java.time.LocalDate
import java.time.temporal.ChronoUnit

object MemoryBoxDates {
    fun dDayText(startDate: LocalDate, today: LocalDate = LocalDate.now()): String {
        val dayCount = ChronoUnit.DAYS.between(startDate, today)

        return if (dayCount < 0) {
            "${-dayCount}일 전"
        } else {
            "${dayCount + 1}일"
        }
    }
}
