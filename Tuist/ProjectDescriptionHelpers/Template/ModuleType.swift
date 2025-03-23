

import Foundation

public enum FeatureType {
    case standard
    case micro
}

public enum ModuleType {
    case app
    case demoapp(name: String)
    case feature(name: String, type: FeatureType)
    case module(name: String)
    case domain(name: String)
}
