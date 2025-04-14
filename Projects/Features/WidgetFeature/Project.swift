import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Widget", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Modules.domain,
        .Modules.widgetData
    ]
)
