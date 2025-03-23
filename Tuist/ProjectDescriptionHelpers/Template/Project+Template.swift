
import ProjectDescription

extension Project {
    public static func configure(
        moduleType: ModuleType,
        product: Product,
        dependencies: [TargetDependency],
        hasResources: Bool = false
    ) -> Project {
        
        var targets: [Target] = []
        var schemes: [Scheme] = []
        let configuration = AppConfiguration()
        
        switch moduleType {
        case .app:
            let appTarget = Target.target(
                name: configuration.projectName,
                destinations: configuration.destination,
                product: .app,
                bundleId: configuration.bundleIdentifier,
                deploymentTargets: configuration.deploymentTarget,
                infoPlist: .extendingDefault(with: configuration.infoPlist),
                sources: ["Sources/**"],
                resources: [.glob(pattern: "Resources/**", excluding: [])],
                entitlements: configuration.entitlements,
                dependencies: dependencies,
                settings: configuration.setting
            )
            targets.append(appTarget)
            
            let appScheme = Scheme.configureAppScheme(
                schemeName: configuration.projectName
            )
            schemes = appScheme
            
            return Project(
                name: configuration.projectName,
                organizationName: configuration.organizationName,
                settings: configuration.setting,
                targets: targets,
                schemes: schemes
            )
        case let .demoapp(name):
            
            let demoAppName = "\(name)_demo_app"
        
            let appTarget = Target.target(
                name: demoAppName,
                destinations: configuration.destination,
                product: .app,
                bundleId: "\(configuration.bundleIdentifier).demo.\(name.lowercased())",
                deploymentTargets: configuration.deploymentTarget,
                infoPlist: .extendingDefault(with: configuration.demoInfoPlist(name: name)),
                sources: ["Sources/**"],
                resources: [.glob(pattern: "Resources/**", excluding: [])],
                entitlements: configuration.entitlements,
                dependencies: dependencies,
                settings: configuration.setting
            )
            targets.append(appTarget)
            
            let appScheme = Scheme.configureAppScheme(
                schemeName: demoAppName
            )
            schemes = appScheme
            
            return Project(
                name: demoAppName,
                organizationName: configuration.organizationName,
                settings: configuration.setting,
                targets: targets,
                schemes: schemes
            )
        
        case let .feature(name, type):
            let featureTargetName = "\(name)Feature"
            switch type {
            case .standard:
                let featureTarget = Target.target(
                    name: featureTargetName,
                    destinations: configuration.destination,
                    product: product,
                    bundleId: "\(configuration.bundleIdentifier).feature.\(name.lowercased())",
                    deploymentTargets: configuration.deploymentTarget,
                    sources: ["Sources/**"],
                    dependencies: dependencies
                )
                targets.append(featureTarget)
                
                let testTargetName = "\(featureTargetName)Tests"
                let testTarget = Target.target(
                    name: testTargetName,
                    destinations: configuration.destination,
                    product: .unitTests,
                    bundleId: "\(configuration.bundleIdentifier).feature.\(name.lowercased()).test",
                    deploymentTargets: configuration.deploymentTarget,
                    sources: ["Tests/Sources/**"],
                    dependencies: [.target(name: featureTargetName)]
                )
                targets.append(testTarget)
                
                let featureScheme = Scheme.configureScheme(
                    schemeName: featureTargetName
                )
                schemes.append(featureScheme)
                
                let demoTarget = Target.target(
                    name: "\(name)_demo_app",
                    destinations: configuration.destination,
                    product: .app,
                    bundleId: "\(configuration.bundleIdentifier).demo.\(name.lowercased())",
                    deploymentTargets: configuration.deploymentTarget,
                    infoPlist: .extendingDefault(with: configuration.demoInfoPlist(name: name)),
                    sources: ["Sources/**"],
                    resources: [.glob(pattern: "Resources/**", excluding: [])],
                    entitlements: configuration.entitlements,
                    dependencies: dependencies,
                    settings: configuration.setting
                )
                
                targets.append(demoTarget)
                
                return Project(
                    name: featureTargetName,
                    organizationName: configuration.organizationName,
                    settings: configuration.commonSettings,
                    targets: targets,
                    schemes: schemes
                )
            case .micro:
                return configureMicroFeatureProject(
                    configuration: configuration,
                    product: product,
                    name: featureTargetName,
                    organizationName: configuration.organizationName,
                    targets: targets,
                    dependencies: dependencies,
                    schemes: schemes,
                    settings: configuration.setting
                )
            }
            
        case let .module(name):
            let moduleTarget = Target.target(
                name: name,
                destinations: configuration.destination,
                product: product,
                bundleId: "\(configuration.bundleIdentifier).\(name.lowercased())",
                deploymentTargets: configuration.deploymentTarget,
                sources: ["Sources/**"],
                resources: hasResources ? ["Resources/**"] : [],
                dependencies: dependencies
            )
            targets.append(moduleTarget)
            
            let testTargetName = "\(name)Tests"
            let testTarget = Target.target(
                name: testTargetName,
                destinations: configuration.destination,
                product: .unitTests,
                bundleId: "\(configuration.bundleIdentifier).\(name.lowercased()).test",
                deploymentTargets: configuration.deploymentTarget,
                sources: ["Tests/Sources/**"],
                dependencies: [.target(name: name)]
            )
            targets.append(testTarget)
            
            let moduleScheme = Scheme.configureScheme(
                schemeName: name
            )
            
            schemes.append(moduleScheme)
            
            return Project(
                name: name,
                organizationName: configuration.organizationName,
                settings: configuration.commonSettings,
                targets: targets,
                schemes: schemes
            )
        case let .domain(name):
            let domainName = name == "Domain" ? "Domain" : "\(name)Domain"
            let moduleTarget = Target.target(
                name: domainName,
                destinations: configuration.destination,
                product: product,
                bundleId: "\(configuration.bundleIdentifier).\(domainName.lowercased())",
                deploymentTargets: configuration.deploymentTarget,
                sources: ["Sources/**"],
                resources: hasResources ? ["Resources/**"] : [],
                dependencies: dependencies
            )
            targets.append(moduleTarget)
            
            let testTargetName = "\(domainName)Tests"
            let testTarget = Target.target(
                name: testTargetName,
                destinations: configuration.destination,
                product: .unitTests,
                bundleId: "\(configuration.bundleIdentifier).\(domainName.lowercased()).test",
                deploymentTargets: configuration.deploymentTarget,
                sources: ["Tests/Sources/**"],
                dependencies: [.target(name: domainName)]
            )
            targets.append(testTarget)
            
            let moduleScheme = Scheme.configureScheme(
                schemeName: domainName
            )
            
            schemes.append(moduleScheme)
            
            return Project(
                name: domainName,
                organizationName: configuration.organizationName,
                settings: configuration.commonSettings,
                targets: targets,
                schemes: schemes
            )
        }
    }
    
    // MARK: MicroFeature 생성
    private static func configureMicroFeatureProject(
        configuration: AppConfiguration,
        product: Product,
        name: String,
        organizationName: String,
        targets: [Target],
        dependencies: [TargetDependency],
        schemes: [Scheme],
        settings: Settings
    ) -> Project {
        
        // Interface 타겟
        let interfaceTargetName = "\(name)Interface"
        let interfaceTarget = Target.target(
            name: interfaceTargetName,
            destinations: configuration.destination,
            product: product,
            bundleId: "\(configuration.bundleIdentifier).\(name.lowercased())Interface",
            deploymentTargets: configuration.deploymentTarget,
            infoPlist: .default,
            sources: ["Interface/Sources/**"]
//            dependencies: dependencies
        )
        
        // Framework 타겟
        let frameworkTargetName = name
        let frameworkTarget = Target.target(
            name: frameworkTargetName,
            destinations: configuration.destination,
            product: product,
            bundleId: "\(configuration.bundleIdentifier).\(name.lowercased())",
            deploymentTargets: configuration.deploymentTarget,
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies + [ .target(name: interfaceTargetName) ]
//            [
//                .target(name: interfaceTargetName),
//                dependencies
//            ]
        )
        
        
        let demoTarget = Target.target(
            name: "\(name)_demo_app",
            destinations: configuration.destination,
            product: .app,
            bundleId: "\(configuration.bundleIdentifier).demo.\(name.lowercased())",
            deploymentTargets: configuration.deploymentTarget,
            infoPlist: .extendingDefault(with: configuration.demoInfoPlist(name: name)),
            sources: ["Demo/Sources/**",
                     "Sources/**"],
            resources: [.glob(pattern: "Resources/**", excluding: [])],
            entitlements: configuration.entitlements,
            dependencies: [
                .target(name: frameworkTargetName)
            ],
            settings: configuration.setting
        )
        
        // Test 타겟
//        let testTargetName = "\(name)Test"
//        let testTarget = Target.target(
//            name: testTargetName,
//            destinations: configuration.destination,
//            product: product,
//            bundleId: "\(configuration.bundleIdentifier).\(name.lowercased())Test",
//            deploymentTargets: configuration.deploymentTarget,
//            infoPlist: .default,
//            sources: ["Test/Sources/**"],
//            dependencies: [
//                .target(name: interfaceTargetName)
//            ]
//        )
        
        // Tests 타겟
        let testsTargetName = "\(name)Tests"
        let testsTarget = Target.target(
            name: testsTargetName,
            destinations: configuration.destination,
            product: .unitTests,
            bundleId: "\(configuration.bundleIdentifier).\(name.lowercased())Tests",
            deploymentTargets: configuration.deploymentTarget,
            infoPlist: .default,
            sources: ["Tests/Sources/**"],
            dependencies: [
                .target(name: frameworkTargetName),
            ]
        )
        
        let targets = [interfaceTarget, frameworkTarget, demoTarget, testsTarget, /*testTarget*/]
        
        let scheme = Scheme.configureDemoAppScheme(schemeName: name)
        
        // 프로젝트 생성
        return Project(
            name: name,
            organizationName: organizationName,
            settings: settings,
            targets: targets,
            schemes: [scheme]
        )
    }
}
