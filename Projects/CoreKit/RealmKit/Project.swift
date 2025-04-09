//
//  Project.swift
//  Manifests
//
//  Created by 박지봉 on 2/7/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "RealmKit"),
    product: .framework,
    dependencies: [
        .external(name: "ComposableArchitecture"),
        .external(name: "RealmSwift"),
        .external(name: "Realm")
    ]
)
