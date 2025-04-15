import Foundation
import Testing
import ComposableArchitecture
@testable import CalendarFeature

@MainActor
struct CalendarTests {
    
    @Test
    func basics() async {
        let store = TestStore(initialState: CalendarReducer.State(selectedMonth: Date())) {
            CalendarReducer()
        }
        
        let testDate = Date()
        
        await store.send(.selectedDateChange(testDate)) { state in
            state.selectedDate = testDate
        }
        
        await store.send(.selectedMonthChange(testDate)) { state in
            state.selectedMonth = testDate
        }
        
        await store.receive(\.searchAllData)
 
        await store.receive(\.scheduleDataLoaded, timeout: 10)
          
        await store.receive(\.diaryDataLoaded, timeout: 10)
        
        await store.receive(\.todoDataLoaded, timeout: 10)
        
    }
}
