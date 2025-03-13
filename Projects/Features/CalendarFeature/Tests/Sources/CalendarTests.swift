import Foundation
import ComposableArchitecture
import Testing
import CalendarFeature


@testable import Calendar_demo_app

@MainActor
struct CalendarTests {
    
    @Test
    func basics() async {
        let testStore = TestStore(initialState: CalendarReducer.State(selectedMonth: Date())) {
            CalendarReducer()
        }
        
        await testStore.send(.selectedDateChange(Date())) { store in
            
        }
    }
}
