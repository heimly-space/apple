//
//  APIClientTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 27.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct APIClientTests {
    private struct TestRequest: Codable, Sendable, Equatable {
        let name: String
    }
    
    private struct TestResponse: Codable, Sendable, Equatable {
        let id: Int
    }
    
    @Test
    func constructsRequestAndDecodesResponse() async throws {
        let expectedBody = TestRequest(name: "Kitchen")
        
        let httpClient = MockHTTPClient { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/api/v1/households")
            
            let components = try #require(
                request.url.flatMap {
                    URLComponents(
                        url: $0,
                        resolvingAgainstBaseURL: false
                    )
                }
            )
            
            #expect(
                components.queryItems
                == [URLQueryItem(name: "invite", value: "abc")]
            )
            
            #expect(
                request.value(forHTTPHeaderField: "Accept")
                == "application/json"
            )
            
            #expect(
                request.value(forHTTPHeaderField: "Content-Type")
                == "application/json"
            )
            
            #expect(
                request.value(forHTTPHeaderField: "Authorization")
                == "Bearer token"
            )
            
            let bodyData = try #require(request.httpBody)
            let body = try JSONDecoder().decode(
                TestRequest.self,
                from: bodyData
            )
            
            #expect(body == expectedBody)
            
            return HTTPResponse(
                data: Data(#"{"id":42}"#.utf8),
                statusCode: 201,
                url: request.url
            )
        }
        
        let baseURL = try #require(
            URL(string: "https://example.com/api/v1")
        )
        
        let client = APIClient(
            baseURL: baseURL,
            httpClient: httpClient
        )
        
        let endpoint = Endpoint<TestRequest, TestResponse>(
            method: .post,
            path: ["households"],
            queryItems: [
                URLQueryItem(name: "invite", value: "abc")
            ],
            headers: [
                "Authorization": "Bearer token"
            ],
            body: expectedBody
        )
        
        let response = try await client.send(endpoint)
        
        #expect(response == TestResponse(id: 42))
    }
}
