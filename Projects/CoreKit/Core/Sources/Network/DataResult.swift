//
//  DataResult.swift
//  Core
//
//  Created by 박지봉 on 5/9/25.
//  Copyright © 2025 JIBONG PARK. All rights reserved.
//

public struct DataResult<Payload> {
    public let data: Payload?
    public let error: Error?
    
    public init(_ data: Payload? = nil, error: Error? = nil) {
        self.data = data
        self.error = error
    }
    
    public var isSuccess: Bool {
        error == nil
    }
}
