import UIKit
import RealmSwift
import CalendarData

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let schemaVersion: UInt64 = 5
        
        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < schemaVersion {
                    migration.enumerateObjects(ofType: ScheduleDTO.className()) { oldObject, newObject in
                        newObject?["color"] = 0
                    }
                    
                    migration.enumerateObjects(ofType: TodoDTO.className()) { oldObject, newObject in
                        newObject?["color"] = 0
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    
                    migration.enumerateObjects(ofType: DiaryDTO.className()) { oldObject, newObject in
                        if
                            let dateString = oldObject?["date"] as? String,
                            let dateValue  = dateFormatter.date(from: dateString)
                        {
                            newObject?["date"] = dateValue
                        }
                        
                        newObject?["id"] = UUID().uuidString
                        
                        newObject?["author"] = ""
                        newObject?["shared"] = []
                        
                        newObject?["createdAt"] = Date()
                        newObject?["updatedAt"] = Date()
                        
                    }
                    
                    migration.enumerateObjects(ofType: ScheduleDTO.className()) { oldObject, newObject in
                        if let oldId = oldObject?["id"] as? Int {
                            newObject?["id"] = String(oldId)
                        }
                        newObject?["author"] = ""
                        newObject?["shared"] = []
                        
                        newObject?["createdAt"] = Date()
                        newObject?["updatedAt"] = Date()
                    }
                    
                    migration.enumerateObjects(ofType: TodoDTO.className()) { oldObject, newObject in
                        if let oldId = oldObject?["id"] as? Int {
                            newObject?["id"] = String(oldId)
                        }
                        newObject?["author"] = ""
                        newObject?["shared"] = []
                        
                        newObject?["createdAt"] = Date()
                        newObject?["updatedAt"] = Date()
                    }
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    }
        
    func sceneDidDisconnect(_ scene: UIScene) {
    }
}
