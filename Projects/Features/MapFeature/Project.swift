import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Map", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Modules.domain,
        .Modules.mapData,
        .external(name: "ComposableArchitecture")
    ]
)
