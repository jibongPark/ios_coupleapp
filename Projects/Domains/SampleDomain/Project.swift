import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .domain(name: "Sample"),
    product: .framework,
    dependencies: [
//        .Modules.shared
    ]
)
