import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .domain(name: "Canvas"),
    product: .framework,
    dependencies: [
        .Core.core,
        .external(name: "ComposableArchitecture"),
    ]
)
