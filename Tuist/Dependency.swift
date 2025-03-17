//
//  Dependency.swift
//  Manifests
//
//  Created by 박지봉 on 3/13/25.
//

import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        // ComposableArchitecture 의존성을 추가합니다.
        .remote(
            .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.16.1")
        )
    ],
    platforms: [.iOS]
)
