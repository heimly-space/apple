//
//  Endpoint.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 24.09.2026.
//

import Foundation

nonisolated struct NoRequestBody: Encodable, Sendable {}

nonisolated struct Endpoint<
    Request: Encodable & Sendable,
    Response: Decodable & Sendable
>: Sendable {
    let method: HTTPMethod
    let path: [String]
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Request?
    let successfulStatusCodes: Range<Int>
    
    init(
        method: HTTPMethod,
        path: [String],
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Request? = nil,
        successfulStatusCodes: Range<Int> = 200..<300
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.successfulStatusCodes = successfulStatusCodes
    }
}
