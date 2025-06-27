//
//  AuthInterceptor.swift
//  CommonData
//
//  Created by 박지봉 on 5/14/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya
import Foundation
import Alamofire
import Core
import Dependencies

public final class AuthInterceptor: RequestInterceptor {
    
    @Dependency(\.authManager) var authManager
    
    private let url = Bundle.main.object(forInfoDictionaryKey:"BASE_URL")
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.url?.absoluteString.hasPrefix(url as! String) == true
        else {
            completion(.success(urlRequest))
            return
        }
        
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer \(authManager.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }

    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401
        else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        let refreshProvider = MoyaProvider<RefreshAPI>(session: .default)
        
        if let token = authManager.refreshToken {
            refreshProvider.request(.refresh(token: token)) { [self] result in
                switch result {
                case .success(let response):
                    do {
                        let convertResponse: APIResponse<AuthTokens> = try response.mapAPIResponse(AuthTokens.self)
                        
                        let accessToken = convertResponse.data!.accessToken
                        let refreshToken = convertResponse.data!.newRefreshToken
                        authManager.updateToken(access: accessToken, refresh: refreshToken)
                        
                        print("Retry-토큰 재발급 성공")
                        completion(.retry)
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    authManager.clear()
                    completion(.doNotRetryWithError(error))
                }
            }
        }
        
        completion(.doNotRetryWithError(error))
    }
}

private enum AuthInterceptorKey: DependencyKey {
    static var liveValue: AuthInterceptor = AuthInterceptor()
    static var testValue: AuthInterceptor = AuthInterceptor()
}

public extension DependencyValues {
    var authInterceptor: AuthInterceptor {
        get { self[AuthInterceptorKey.self] }
        set { self[AuthInterceptorKey.self] = newValue }
    }
}
