//
//  ServerConnectionService.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation

nonisolated enum ServerConnectionError: Error, Sendable {
    case unhealthy(status: String)
}

nonisolated protocol ServerConnecting: Sendable {
    func verifyServer(at baseURL: URL) async throws
}

nonisolated struct ServerConnectionService: ServerConnecting {
    private let httpClient: any HTTPClient
    
    init(
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        self.httpClient = httpClient
    }
    
    func verifyServer(at baseURL: URL) async throws {
        let apiClient = APIClient(
            baseURL: baseURL,
            httpClient: httpClient
        )
        
        let response = try await apiClient.send(HealthEndpoint.check)
        
        guard response.status == "ok" else {
            throw ServerConnectionError.unhealthy(status: response.status)
        }
    }
}
