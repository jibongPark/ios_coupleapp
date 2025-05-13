import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Setting", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core
    ]
)