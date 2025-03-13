import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .demoapp(name: "Calendar"),
    product: .app,
    dependencies: [
        .Features.Calendar.Feature,
        .external(name: "ComposableArchitecture")
    ]
)
