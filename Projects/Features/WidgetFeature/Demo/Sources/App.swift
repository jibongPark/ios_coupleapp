import SwiftUI
import ComposableArchitecture

@main
struct WidgetDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Dependency(\.widgetFeature) var widgetFeature
    
    var body: some Scene {
        WindowGroup {
            AnyView(widgetFeature.makeView())
        }
    }
}
