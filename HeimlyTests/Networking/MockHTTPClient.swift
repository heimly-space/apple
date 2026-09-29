//
//  MockHTTPClient.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation
@testable import Heimly

nonisolated struct MockHTTPClient: HTTPClient {
    let handler: @Sendable (URLRequest) async throws -> HTTPResponse

    func send(_ request: URLRequest) async throws -> HTTPResponse {
        try await handler(request)
    }
}
