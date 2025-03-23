//
//  Project.swift
//  Config
//
//  Created by Junyoung on 1/9/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "MapData"),
    product: .framework,
    dependencies: [
        .Core.realmKit,
        .Modules.domain,
        .external(name: "RealmSwift"),
        .external(name: "Realm"),
//        .Modules.networkModule
    ],
    hasResources: true
)
