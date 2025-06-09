import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .data(name: "Friend"),
    product: .framework,
    dependencies: [
        .external(name: "Moya"),
        .external(name: "ComposableArchitecture"),
        .Domains.Friend.Domain,
        .Core.core
    ]
)
