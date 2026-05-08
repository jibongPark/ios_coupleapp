import Foundation
import SwiftUI
import Testing
@testable import Domain

struct CalendarDomainTests {
    @Test
    func scheduleDateKeysIncludeEveryDayInRange() throws {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 8)))
        let endDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 10)))
        let schedule = ScheduleVO(
            title: "여행",
            startDate: startDate,
            endDate: endDate,
            memo: "",
            color: .red
        )

        #expect(schedule.dateKeys() == ["20260508", "20260509", "20260510"])
    }

    @Test
    func colorHexRoundTripsToInt() {
        let color = Color(int: 0xAA7733)

        #expect(color.toHex() == "AA7733")
        #expect(color.toInt() == 0xAA7733)
    }
}
