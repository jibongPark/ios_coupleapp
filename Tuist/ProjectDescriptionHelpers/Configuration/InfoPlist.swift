
import ProjectDescription
import Foundation

public struct InfoPlist {
    private static let commonInfoPlist: [String: Plist.Value] = [
        "CFBundleDevelopmentRegion": "ko",
        "CFBundleVersion": "1",
        "UILaunchStoryboardName": "Launch Screen",
        "UIUserInterfaceStyle": "Automatic",
        "CFBundleIconName": "AppIcon",
        "LSSupportsOpeningDocumentsInPlace": true,
        "ITSAppUsesNonExemptEncryption": false,
        "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": [
                "UIWindowSceneSessionRoleApplication": [
                    [
                        "UISceneConfigurationName": "Default Configuration",
                        "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                    ],
                ]
            ]
        ]
    ]
    
    static func appInfoPlist(_ appConfiguration: AppConfiguration) -> [String: Plist.Value] {
        
        let kakaoNativeAppKey = ProcessInfo.processInfo.environment["TUIST_KAKAO_NATIVE_APP_KEY"] ?? ""
        let baseURL = ProcessInfo.processInfo.environment["TUIST_BASE_URL"] ?? ""
        
        var infoPlist = commonInfoPlist
        infoPlist["CFBundleShortVersionString"] = .string(appConfiguration.shortVersion)
        infoPlist["CFBundleIdentifier"] = .string(appConfiguration.bundleIdentifier)
        infoPlist["CFBundleDisplayName"] = .string(appConfiguration.displayName)
        infoPlist["LSApplicationQueriesSchemes"] = ["kakaokompassauth",
                                                    "kakaolink",
                                                    "kakaoplus"]
        infoPlist["CFBundleURLTypes"] = [
                  [
                    "CFBundleURLSchemes": [
                      "kakao\(kakaoNativeAppKey)"
                    ]
                  ]
                ]
        infoPlist["KAKAO_APP_KEY"] = .string(kakaoNativeAppKey)
        infoPlist["BASE_URL"] = .string(baseURL)
        
        return infoPlist
    }
    
    static func demoAppInfoPlist(_ appConfiguration: AppConfiguration, name: String) -> [String: Plist.Value] {
        
        let kakaoNativeAppKey = ProcessInfo.processInfo.environment["TUIST_KAKAO_NATIVE_APP_KEY"] ?? ""
        let baseURL = ProcessInfo.processInfo.environment["TUIST_BASE_URL"] ?? ""
        
        var infoPlist = commonInfoPlist
        infoPlist["CFBundleShortVersionString"] = .string(appConfiguration.shortVersion)
        infoPlist["CFBundleIdentifier"] = "\(appConfiguration.bundleIdentifier).demo.\(name.lowercased())"
        infoPlist["CFBundleDisplayName"] = "\(name) demo"
        infoPlist["LSApplicationQueriesSchemes"] = ["kakaokompassauth",
                                                    "kakaolink",
                                                    "kakaoplus"]
        infoPlist["CFBundleURLTypes"] = [
                  [
                    "CFBundleURLSchemes": [
                      "kakao\(kakaoNativeAppKey)"
                    ]
                  ]
                ]
        infoPlist["KAKAO_APP_KEY"] = .string(kakaoNativeAppKey)
        infoPlist["BASE_URL"] = .string(baseURL)
        return infoPlist
    }
}
