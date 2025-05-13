
import ProjectDescription

public extension TargetDependency {
    struct Domains {
        public struct Auth {}
        public struct Sample {}
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
