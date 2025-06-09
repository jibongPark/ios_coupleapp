import SwiftUI

import ComposableArchitecture
import FriendFeature

@main
struct FriendDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Dependency(\.friendFeature) var friendFeature
    
    var body: some Scene {
        WindowGroup {
            AnyView(
                friendFeature.makeView()
            )
        }
    }
}
