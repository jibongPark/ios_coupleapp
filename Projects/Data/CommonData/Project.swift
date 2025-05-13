import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .data(name: "Common"),
    product: .framework,
    dependencies: [
        .external(name: "Moya")
    ]
)
