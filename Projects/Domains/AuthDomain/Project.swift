import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .domain(name: "Auth"),
    product: .framework,
    dependencies: [
        .Core.core
    ]
)
