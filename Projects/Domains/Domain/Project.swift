import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .domain(name: "Domain"),
    product: .framework,
    dependencies: [
        .external(name: "ComposableArchitecture"),
        .Core.core
    ]
)
