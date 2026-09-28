//
//  ServerConnectionServiceTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct ServerConnectionServiceTests {
    @Test
    func acceptsHealthyHeimlyServer() async throws {
        let httpClient = MockHTTPClient { request in
            #expect(request.httpMethod == "GET")
            #expect(
                request.url?.absoluteString
                == "https://example.com/health"
            )
            #expect(
                request.value(
                    forHTTPHeaderField: "Accept"
                ) == "application/json"
            )
            
            return HTTPResponse(
                data: Data(#"{"status":"ok"}"#.utf8),
                statusCode: 200,
                url: request.url
            )
        }
        
        let service = ServerConnectionService(
            httpClient: httpClient
        )
        
        try await service.verifyServer(
            at: URL(string: "https://example.com")!
        )
    }
    
    @Test
    func rejectsUnhealthyServer() async throws {
        let httpClient = MockHTTPClient { request in
            HTTPResponse(
                data: Data(#"{"status":"maintenance"}"#.utf8),
                statusCode: 200,
                url: request.url
            )
        }
        
        let service = ServerConnectionService(
            httpClient: httpClient
        )
        
        let baseURL = try #require(
            URL(string: "https://example.com")
        )
        
        do {
            try await service.verifyServer(at: baseURL)
            Issue.record("Expected the server to be rejected")
        } catch let error as ServerConnectionError {
            guard case .unhealthy(let status) = error else {
                Issue.record("Unexpected connection error: \(error)")
                return
            }
            
            #expect(status == "maintenance")
        }
    }
    
    @Test
    func rejectsUnsuccessfulHTTPStatus() async throws {
        let httpClient = MockHTTPClient { request in
            HTTPResponse(
                data: Data(),
                statusCode: 503,
                url: request.url
            )
        }
        
        let service = ServerConnectionService(
            httpClient: httpClient
        )
        
        let baseURL = try #require(
            URL(string: "https://example.com")
        )
        
        do {
            try await service.verifyServer(at: baseURL)
            Issue.record("Expected HTTP status failure")
        } catch let error as APIError {
            guard case .unacceptableStatusCode(let code, _) = error else {
                Issue.record("Unexpected API error: \(error)")
                return
            }
            
            #expect(code == 503)
        }
    }
    
    @Test
    func rejectsUnexpectedHealthResponse() async throws {
        let httpClient = MockHTTPClient { request in
            HTTPResponse(
                data: Data(#"{"state":"ok"}"#.utf8),
                statusCode: 200,
                url: request.url
            )
        }
        
        let service = ServerConnectionService(
            httpClient: httpClient
        )
        
        let baseURL = try #require(
            URL(string: "https://example.com")
        )
        
        do {
            try await service.verifyServer(at: baseURL)
            Issue.record("Expected response decoding failure")
        } catch let error as APIError {
            guard case .responseDecodingFailed = error else {
                Issue.record("Unexpected API error: \(error)")
                return
            }
        }
    }
}
