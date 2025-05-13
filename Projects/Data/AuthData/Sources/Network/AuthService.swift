//
//  AuthService.swift
//  AuthData
//
//  Created by 박지봉 on 5/8/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation
import AuthDomain

enum AuthService {
    case login(type: LoginType, jwt: String, name: String)
    case refresh(token: String)
}

extension AuthService: TargetType {
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    
    var baseURL: URL {
        let url = Bundle.main.object(forInfoDictionaryKey:"BASE_URL")
        
        if let urlString = url as? String {
            return URL(string: urlString)!
        } else {
            fatalError("URL String not found")
        }
    }
    
    var path: String {
        switch self {
        case .login: return "/login"
        case .refresh: return "/refresh"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        switch self {
        case let .login(type, jwt, name):
            return .requestParameters(parameters: ["loginType": type.rawValue, "jwt": jwt, "name": name], encoding: JSONEncoding.default)
            
        case let .refresh(jwt):
            return .requestParameters(parameters: ["refreshToken": jwt], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        return Data()
    }
}
