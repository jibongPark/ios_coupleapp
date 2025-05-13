
import ProjectDescription

public extension TargetDependency {
    struct Data {
        public struct Common {}
        public struct Auth {}
        public struct Calendar {}
        public struct Map {}
        public struct Widget {}
    }
}

public extension TargetDependency.Data {
    static func project(name: String) -> TargetDependency {
        return .project(target: name, path: .relativeToData(name))
    }
}



public extension TargetDependency.Data.Calendar {
    static let name = "Calendar"
    
    static let Data = TargetDependency.Data.project(name: "\(name)Data")
}

public extension TargetDependency.Data.Map {
    static let name = "Map"
    
    static let Data = TargetDependency.Data.project(name: "\(name)Data")
}

public extension TargetDependency.Data.Widget {
    static let name = "Widget"
    
    static let Data = TargetDependency.Data.project(name: "\(name)Data")
}

public extension TargetDependency.Data.Auth {
    static let name = "Auth"
    
    static let Data = TargetDependency.Data.project(name: "\(name)Data")
}

public extension TargetDependency.Data.Common {
    static let name = "Common"
    
    static let Data = TargetDependency.Data.project(name: "\(name)Data")
}
