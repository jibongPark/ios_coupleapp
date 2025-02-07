import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .module(name: "DesignKit"),
    product: .framework,
    dependencies: [
        .Modules.domain,
//        .Library.snapKit
    ]
)
