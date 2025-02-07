import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .app,
    product: .app,
    dependencies: [
//        .Features.Root.Feature,
        .Modules.calendarData,
        .external(name: "ComposableArchitecture", condition: nil)
    ]
)
