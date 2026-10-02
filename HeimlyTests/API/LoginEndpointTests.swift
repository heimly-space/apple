//
//  LoginEndpointTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct LoginEndpointTests {
    @Test
    func sendsLoginRequestAndDecodesTokens() async throws {
        let httpClient = MockHTTPClient { request in
            #expect(request.httpMethod == "POST")
            #expect(
                request.url?.absoluteString
                    == "https://example.com/api/v1/auth/login"
            )
            #expect(
                request.value(forHTTPHeaderField: "Accept")
                    == "application/json"
            )
            #expect(
                request.value(forHTTPHeaderField: "Content-Type")
                    == "application/json"
            )
            
            let bodyData = try #require(request.httpBody)
            let body = try #require(
                JSONSerialization.jsonObject(with: bodyData)
                as? [String: String]
            )
            
            #expect(body["login"] == "alice")
            #expect(body["password"] == "secret123")
            
            return HTTPResponse(
                data: Data(
                    #"""
                    {
                        "access_token": "access-token",
                        "refresh_token": "refresh-token"
                    }
                    """#.utf8
                ),
                statusCode: 200,
                url: request.url
            )
        }
        
        let baseURL = try #require(
            URL(string: "https://example.com")
        )
        let client = APIClient(
            baseURL: baseURL,
            httpClient: httpClient
        )

        let tokens = try await client.send(
            LoginEndpoint.login(
                login: "alice",
                password: "secret123"
            )
        )

        #expect(tokens.accessToken == "access-token")
        #expect(tokens.refreshToken == "refresh-token")
    }
}
