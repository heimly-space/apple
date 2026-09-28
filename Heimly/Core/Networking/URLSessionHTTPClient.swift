//
//  URLSessionHTTPClient.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation

nonisolated struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func send(_ request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            throw HTTPClientError.nonHTTPResponse
        }
        
        return HTTPResponse(data: data, statusCode: response.statusCode, url: response.url)
    }
}
