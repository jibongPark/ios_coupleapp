//
//  RefreshAPI.swift
//  CommonData
//
//  Created by 박지봉 on 5/14/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation
import Core

enum RefreshAPI {
    case refresh(token: String)
}

extension RefreshAPI: TargetType {
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    
    var baseURL: URL {
        ConfigManager.shared.apiBaseURL ?? ConfigManager.fallbackBaseURL
    }
    
    var path: String {
        switch self {
        case .refresh: return "/refresh"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        switch self {
        case let .refresh(jwt):
            return .requestParameters(parameters: ["refreshToken": jwt], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
