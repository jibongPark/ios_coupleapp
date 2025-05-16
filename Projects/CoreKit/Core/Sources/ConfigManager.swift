//
//  ConfigManager.swift
//  Core
//
//  Created by 박지봉 on 5/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

public final class ConfigManager {
    public static let shared = ConfigManager()
    
    private var storage: [String: Any] = [:]
    
    private init() {}
    
    public func set<T>(_ key: String, _ value: T) {
        storage[key] = value
    }
    
    public func get<T>(_ key: String) -> T? {
        storage[key] as? T
    }
}
