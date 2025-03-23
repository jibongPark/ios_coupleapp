import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "CalendarData"),
    product: .framework,
    dependencies: [
        .Core.sqlite
//        .Modules.networkModule
    ]
)
