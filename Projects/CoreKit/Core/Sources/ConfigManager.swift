//
//  ConfigManager.swift
//  Core
//
//  Created by 박지봉 on 5/15/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation

public final class ConfigManager {
    public static let shared = ConfigManager()

    public static let fallbackBaseURL = URL(string: "https://example.invalid")!
    public static let missingAPIBaseURLMessage = "서버 주소 설정이 없습니다."

    private var storage: [String: Any] = [:]

    private init() {}

    public var apiBaseURL: URL? {
        Self.apiBaseURL(from: Bundle.main.object(forInfoDictionaryKey: "BASE_URL"))
    }

    public var hasValidAPIBaseURL: Bool {
        apiBaseURL != nil
    }

    public static func apiBaseURL(from rawValue: Any?) -> URL? {
        guard let value = rawValue as? String else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              url.scheme != nil,
              url.host != nil
        else { return nil }

        return url
    }

    public func set<T>(_ key: String, _ value: T) {
        storage[key] = value
    }

    public func get<T>(_ key: String) -> T? {
        storage[key] as? T
    }
}
