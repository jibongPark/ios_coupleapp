import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .data(name: "Canvas"),
    product: .framework,
    dependencies: [
        .Core.core,
        .Domains.Canvas.Domain,
        .external(name: "ComposableArchitecture"),
    ]
)
