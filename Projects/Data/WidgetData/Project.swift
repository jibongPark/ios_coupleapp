
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "WidgetData"),
    product: .framework,
    dependencies: [
        .Modules.domain,
        .Core.core
    ],
    hasResources: false
)
