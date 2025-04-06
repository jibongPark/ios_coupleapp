import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "CalendarData"),
    product: .framework,
    dependencies: [
        .Modules.domain,
        .Core.realmKit,
        .external(name: "RealmSwift"),
        .external(name: "Realm"),
    ]
)
