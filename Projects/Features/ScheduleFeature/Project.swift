import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Schedule", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Modules.calendarData
    ]
)
