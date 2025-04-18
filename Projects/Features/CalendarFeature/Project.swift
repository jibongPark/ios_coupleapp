import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Calendar", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Modules.calendarData,
        .external(name: "ComposableArchitecture")
    ]
)
