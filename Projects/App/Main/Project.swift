import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .app,
    product: .app,
    dependencies: [
        .Features.Calendar.Feature,
        .Features.Map.Feature,
    ]
)
