
import ProjectDescription

public extension TargetDependency {
    struct Domains {
        public struct Friend {}
        public struct Auth {}
        public struct Sample {}
        public struct Canvas {}
    }
}

public extension TargetDependency.Domains {
    static func project(name: String) -> TargetDependency {
        return .project(target: name, path: .relativeToDomain(name))
    }
}



public extension TargetDependency.Domains.Sample {
    static let name = "Sample"
    
    static let Domain = TargetDependency.Domains.project(name: "\(name)Domain")
}

public extension TargetDependency.Domains.Auth {
    static let name = "Auth"
    
    static let Domain = TargetDependency.Domains.project(name: "\(name)Domain")
}

public extension TargetDependency.Domains.Friend {
    static let name = "Friend"
    
    static let Domain = TargetDependency.Domains.project(name: "\(name)Domain")
}


public extension TargetDependency.Domains.Canvas {
    static let name = "Canvas"

    static let Domain = TargetDependency.Domains.project(name: "\(name)Domain")
}
