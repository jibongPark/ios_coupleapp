import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Canvas", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Data.Canvas.Data,
        .Domains.Canvas.Domain,
        .external(name: "ComposableArchitecture"),
    ],
    interfaceDependencies: []
)
