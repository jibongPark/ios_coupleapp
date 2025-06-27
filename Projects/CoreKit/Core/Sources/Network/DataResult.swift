//
//  DataResult.swift
//  Core
//
//  Created by 박지봉 on 5/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

import Moya

public struct DataResult<Payload> {
    public let isSuccess: Bool
    public let data: Payload?
    public let message: String
    
    public init(isSuccess: Bool, data: Payload? = nil, message: String? = nil) {
        self.isSuccess = isSuccess
        self.data = data
        self.message = message ?? ""
    }
    
    public init(message: String) {
        self.isSuccess = false
        self.data = nil
        self.message = message
    }
}
