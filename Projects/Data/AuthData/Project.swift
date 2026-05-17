import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .data(name: "Auth"),
    product: .framework,
    dependencies: [
        .Domains.Auth.Domain,
        .Core.core,
        .Data.Common.Data,
        .external(name: "ComposableArchitecture"),
        .external(name: "Moya")
    ]
)
