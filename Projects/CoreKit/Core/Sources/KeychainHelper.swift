//
//  KeychainHelper.swift
//  Core
//
//  Created by 박지봉 on 5/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Foundation
import Security
import Dependencies

public final class KeychainHelper {
    public static let standard = KeychainHelper()

    private init() {}

    public func save(_ string: String, service: String, account: String) throws {
        let data = Data(string.utf8)
        // 1) 이미 있으면 업데이트
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String   : data
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            // 2) 없으면 새로 추가
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    public func read(service: String, account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String         : kSecClassGenericPassword,
            kSecAttrService as String   : service,
            kSecAttrAccount as String   : account,
            kSecReturnData as String    : true,
            kSecMatchLimit as String    : kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)
        guard
            let data = item as? Data,
            let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

private enum KeychainHelperKey: DependencyKey {
    static var liveValue = KeychainHelper.standard
}

public extension DependencyValues {
    var keyChainHelper: KeychainHelper {
        get { self[KeychainHelperKey.self] }
        set { self[KeychainHelperKey.self] = newValue }
    }
}
