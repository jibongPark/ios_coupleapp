import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .domain(name: "Friend"),
    product: .framework,
    dependencies: [
        .external(name: "ComposableArchitecture"),
        .Core.core
    ]
)
