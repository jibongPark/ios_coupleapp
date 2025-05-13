// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: ["ComposableArchitecture":.framework,
                       "RealmSwift":.framework,
                       "KakaoOpenSDK":.framework,
                       "Moya":.framework]
    )
#endif

let package = Package(
    name: "coupleapp_ios",
    dependencies: [
        // Add your own dependencies here:
         .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.18.0"),
         .package(url: "https://github.com/realm/realm-swift", from: "10.11.0"),
         .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.24.0"),
         .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3")
    ]
)
