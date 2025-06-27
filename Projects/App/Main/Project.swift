import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .app,
    product: .app,
    dependencies: [
        .Features.Calendar.Feature,
        .Features.Map.Feature,
        .Features.Widget.Feature,
        .Features.Setting.Feature,
        .Features.Login.Feature,
        .Features.Friend.Feature,
        .Data.Calendar.Data,
        .external(name: "RealmSwift"),
        .external(name: "Realm"),
    ],
    hasResources: true
)
