//
//  AppConfiguration.swift
//  coupleapp_ios
//
//  Created by 박지봉 on 2/5/25.
//


import Foundation
import ProjectDescription

public struct AppConfiguration {
    
    public init() {}
    
    let workspaceName = "coupleapp"
    let projectName: String = "coupleapp"
    let organizationName = "JIBONG PARK"
    let shortVersion: String = "1.0.2"
    let bundleIdentifier: String = "com.bongbong.coupleapp-ios"
    let displayName: String = "Memory Box"
    let destination: Set<Destination> = [.iPhone, .iPad]
    var entitlements: Entitlements? = nil
    let deploymentTarget: DeploymentTargets = .iOS("17.0")
    
    public var configurationName: ConfigurationName {
        return "TestProject"
    }
    
    var infoPlist: [String : Plist.Value] {
        InfoPlist.appInfoPlist(self)
    }
    
    func demoInfoPlist(name: String) -> [String : Plist.Value] {
        return InfoPlist.demoAppInfoPlist(self, name: name)
    }
    
    public var autoCodeSigning: SettingsDictionary {
        return SettingsDictionary().automaticCodeSigning(devTeam: "6FDQX23XT6")
    }
    
    var setting: Settings {
        return Settings.settings(
            base: autoCodeSigning,
            configurations: XCConfig.project
        )
    }
    
    let commonSettings = Settings.settings(
        base: SettingsDictionary.debugSettings
            .configureAutoCodeSigning()
            .configureVersioning()
            .configureTestability(),
        configurations: XCConfig.framework
    )
}
