//
//  CurrentUserEndpointTests.swift
//  HeimlyTests
//
//  Created on 30.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct CurrentUserEndpointTests {
    @Test
    func sendsAuthorizedRequestAndDecodesCurrentUser() async throws {
        let expectedID = try #require(
            UUID(
                uuidString:
                    "3c5cb5e6-cd90-4b37-a0be-9f85f77f4f31"
            )
        )

        let httpClient = MockHTTPClient { request in
            #expect(request.httpMethod == "GET")
            #expect(
                request.url?.absoluteString
                    == "https://example.com/api/v1/users/me"
            )
            #expect(
                request.value(
                    forHTTPHeaderField: "Authorization"
                ) == "Bearer access-token"
            )
            #expect(request.httpBody == nil)

            return HTTPResponse(
                data: Data(
                    #"""
                    {
                        "id": "3c5cb5e6-cd90-4b37-a0be-9f85f77f4f31",
                        "login": "alice",
                        "email": "alice@example.com",
                        "name": "Alice",
                        "birthday": "1995-10-15"
                    }
                    """#.utf8
                ),
                statusCode: 200,
                url: request.url
            )
        }

        let serverURL = try #require(
            URL(string: "https://example.com")
        )
        let client = APIClient(
            baseURL: serverURL,
            httpClient: httpClient
        )

        let user = try await client.send(
            CurrentUserEndpoint.get(
                accessToken: "access-token"
            )
        )

        #expect(user.id == expectedID)
        #expect(user.login == "alice")
        #expect(user.email == "alice@example.com")
        #expect(user.name == "Alice")
        #expect(user.birthday == "1995-10-15")
    }
}
