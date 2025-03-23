import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "Core"),
    product: .framework,
    dependencies: [
        .external(name: "ComposableArchitecture")
    ]
)
