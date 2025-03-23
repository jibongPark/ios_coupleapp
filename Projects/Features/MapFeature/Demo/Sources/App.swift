import SwiftUI

import ComposableArchitecture
import MapFeature


@main
struct TestProject: App {
    @Dependency(\.mapFeature) var mapFeature
    
    var body: some Scene {
        WindowGroup {
            AnyView(mapFeature.makeView())
        }
    }
}




//import SwiftUI
//import MapFeature
//
//@main
//struct App: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    
//    var body: some Scene {
//        WindowGroup {
//            
//        }
//    }
//}
