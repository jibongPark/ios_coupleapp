import SwiftUI
import Dependencies

@main
struct CalendarDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Dependency(\.calendarFeature) var calendarFeature
    
    var body: some Scene {
        WindowGroup {
            AnyView(calendarFeature.makeView())
        }
    }
}
