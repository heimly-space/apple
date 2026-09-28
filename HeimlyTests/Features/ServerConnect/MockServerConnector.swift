//
//  MockServerConnector.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation
@testable import Heimly

nonisolated struct MockServerConnector: ServerConnecting {
    let handler: @Sendable (URL) async throws -> Void
    
    func verifyServer(at baseURL: URL) async throws {
        try await handler(baseURL)
    }
}
