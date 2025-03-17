// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: ["ComposableArchitecture":.framework,
                       "RealmSwift":.framework,]
    )
#endif

let package = Package(
    name: "coupleapp_ios",
    dependencies: [
        // Add your own dependencies here:
         .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.18.0"),
         .package(url: "https://github.com/realm/realm-swift", from: "10.11.0"),
    ]
)
