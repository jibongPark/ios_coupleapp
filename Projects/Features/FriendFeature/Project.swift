import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Friend", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Data.Friend.Data,
        .Domains.Friend.Domain
    ]
)
