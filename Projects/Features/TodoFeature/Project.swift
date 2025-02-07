import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Todo", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Modules.calendarData
    ]
)
