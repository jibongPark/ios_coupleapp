

import ProjectDescription

extension Scheme {
    static func configureAppScheme(
        schemeName: String
    ) -> [Scheme] {
        let developConfiguration: ConfigurationName = .configuration("Debug")
        let productionConfiguration: ConfigurationName = .configuration("Release")
        
        let buildAction = BuildAction.buildAction(targets: [TargetReference(stringLiteral: schemeName)])
        
        return [
            Scheme.scheme(
                name: schemeName + "-Debug",
                shared: true,
                buildAction: buildAction,
                runAction: .runAction(configuration: developConfiguration),
                archiveAction: .archiveAction(configuration: developConfiguration),
                profileAction: .profileAction(configuration: developConfiguration),
                analyzeAction: .analyzeAction(configuration: developConfiguration)
            ),
            Scheme.scheme(
                name: schemeName + "-Release",
                shared: true,
                buildAction: buildAction,
                runAction: .runAction(configuration: productionConfiguration),
                archiveAction: .archiveAction(configuration: productionConfiguration),
                profileAction: .profileAction(configuration: productionConfiguration),
                analyzeAction: .analyzeAction(configuration: productionConfiguration)
            )
        ]
    }
    
    static func configureDemoAppScheme(
        schemeName: String
    ) -> Scheme {
        let developConfiguration: ConfigurationName = .configuration("Debug")
        
        let buildAction = BuildAction.buildAction(targets: [TargetReference(stringLiteral: schemeName)])
        
        return Scheme.scheme(
            name: schemeName,
            shared: true,
            buildAction: buildAction,
            runAction: .runAction(configuration: developConfiguration),
            archiveAction: .archiveAction(configuration: developConfiguration),
            profileAction: .profileAction(configuration: developConfiguration),
            analyzeAction: .analyzeAction(configuration: developConfiguration)
        )
    }
    
    static func configureScheme(
        schemeName: String
    ) -> Scheme {
        let configuration: ConfigurationName = .configuration("Debug")
        
        let buildAction = BuildAction.buildAction(targets: [TargetReference(stringLiteral: schemeName)])
        
        return Scheme.scheme(
                name: schemeName,
                shared: true,
                buildAction: buildAction,
                runAction: .runAction(configuration: configuration),
                archiveAction: .archiveAction(configuration: configuration),
                profileAction: .profileAction(configuration: configuration),
                analyzeAction: .analyzeAction(configuration: configuration)
        )
    }
}
