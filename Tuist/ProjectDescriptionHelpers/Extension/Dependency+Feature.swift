

import ProjectDescription

public extension TargetDependency {
    struct Features {
        public struct Login {}
        public struct Setting {}
        public struct Widget {}
        public struct Map {}
        public struct Calendar {}
    }
}

public extension TargetDependency.Features {
    static func project(name: String) -> TargetDependency {
        return .project(target: name, path: .relativeToFeature(name))
    }
}

public extension TargetDependency.Features.Calendar {
    static let name = "Calendar"
    
    static let Feature = TargetDependency.Features.project(name: "\(name)Feature")
    static let Interface = TargetDependency.project(target: "\(name)FeatureInterface", path: .relativeToFeature("\(name)Feature"))
}

public extension TargetDependency.Features.Map {
    static let name = "Map"
    
    static let Feature = TargetDependency.Features.project(name: "\(name)Feature")
    static let Interface = TargetDependency.project(target: "\(name)FeatureInterface", path: .relativeToFeature("\(name)Feature"))
}

public extension TargetDependency.Features.Widget {
    static let name = "Widget"
    
    static let Feature = TargetDependency.Features.project(name: "\(name)Feature")
    static let Interface = TargetDependency.project(target: "\(name)FeatureInterface", path: .relativeToFeature("\(name)Feature"))
}

public extension TargetDependency.Features.Setting {
    static let name = "Setting"
    
    static let Feature = TargetDependency.Features.project(name: "\(name)Feature")
    static let Interface = TargetDependency.project(target: "\(name)FeatureInterface", path: .relativeToFeature("\(name)Feature"))
}

public extension TargetDependency.Features.Login {
    static let name = "Login"
    
    static let Feature = TargetDependency.Features.project(name: "\(name)Feature")
    static let Interface = TargetDependency.project(target: "\(name)FeatureInterface", path: .relativeToFeature("\(name)Feature"))
}
