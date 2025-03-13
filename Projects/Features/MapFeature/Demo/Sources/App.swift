import SwiftUI


@main
struct TestProject: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: .init(initialState: MapReducer.State()) {
                    MapReducer()
                }
            )
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
