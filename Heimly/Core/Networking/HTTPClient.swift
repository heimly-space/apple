//
//  HTTPClient.swift
//  Heimly
//
//  Created by Codex on 24.09.2026.
//

import Foundation

nonisolated struct HTTPResponse: Sendable {
    let data: Data
    let statusCode: Int
    let url: URL?
}

nonisolated protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
}
