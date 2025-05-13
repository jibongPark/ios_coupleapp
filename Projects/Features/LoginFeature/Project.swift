import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.configure(
    moduleType: .feature(name: "Login", type: .micro),
    product: .framework,
    dependencies: [
        .Core.core,
        .Data.Auth.Data,
        .external(name:"KakaoSDKCommon"),
        .external(name:"KakaoSDKAuth"),
        .external(name:"KakaoSDKUser"),
    ],
    hasResources: true
)
