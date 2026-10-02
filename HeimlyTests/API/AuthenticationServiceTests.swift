//
//  AuthenticationServiceTests.swift
//  HeimlyTests
//
//  Created on 29.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct AuthenticationServiceTests {
    @Test
    func signsInAndReturnsIdentifiedSession() async throws {
        let expectedUserID = try #require(
            UUID(
                uuidString:
                    "3c5cb5e6-cd90-4b37-a0be-9f85f77f4f31"
            )
        )

        let httpClient = MockHTTPClient { request in
            switch request.url?.path {
            case "/api/v1/auth/login":
                #expect(request.httpMethod == "POST")

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

            case "/api/v1/users/me":
                #expect(request.httpMethod == "GET")
                #expect(
                    request.value(
                        forHTTPHeaderField: "Authorization"
                    ) == "Bearer access-token"
                )

                return HTTPResponse(
                    data: Data(
                        #"""
                        {
                            "id": "3c5cb5e6-cd90-4b37-a0be-9f85f77f4f31",
                            "login": "alice",
                            "email": "alice@example.com",
                            "name": "Alice",
                            "birthday": null
                        }
                        """#.utf8
                    ),
                    statusCode: 200,
                    url: request.url
                )

            default:
                Issue.record(
                    "Unexpected request: \(String(describing: request.url))"
                )

                return HTTPResponse(
                    data: Data(),
                    statusCode: 404,
                    url: request.url
                )
            }
        }

        let serverURL = try #require(
            URL(string: "https://example.com")
        )
        let service = AuthenticationService(
            httpClient: httpClient
        )

        let session = try await service.signIn(
            to: serverURL,
            login: "alice",
            password: "secret123"
        )

        #expect(session.userID == expectedUserID)
        #expect(session.tokens.accessToken == "access-token")
        #expect(session.tokens.refreshToken == "refresh-token")
    }

    @Test
    func mapsUnauthorizedResponseToInvalidCredentials() async throws {
        let service = makeService(
            statusCode: 401
        )

        try await expectSignInError(
            .invalidCredentials,
            from: service
        )
    }

    @Test
    func mapsServerFailureToUnavailable() async throws {
        let service = makeService(
            statusCode: 503
        )

        try await expectSignInError(
            .serverUnavailable,
            from: service
        )
    }

    @Test
    func mapsMalformedSuccessResponseToIncompatibleServer() async throws {
        let service = makeService(
            statusCode: 200,
            data: Data(#"{"unexpected":true}"#.utf8)
        )

        try await expectSignInError(
            .incompatibleServer,
            from: service
        )
    }

    private func makeService(
        statusCode: Int,
        data: Data = Data()
    ) -> AuthenticationService {
        let httpClient = MockHTTPClient { request in
            HTTPResponse(
                data: data,
                statusCode: statusCode,
                url: request.url
            )
        }

        return AuthenticationService(
            httpClient: httpClient
        )
    }

    private func expectSignInError(
        _ expectedError: AuthenticationServiceError,
        from service: AuthenticationService
    ) async throws {
        let serverURL = try #require(
            URL(string: "https://example.com")
        )

        do {
            _ = try await service.signIn(
                to: serverURL,
                login: "alice",
                password: "secret123"
            )

            Issue.record(
                "Expected authentication to fail"
            )
        } catch let error as AuthenticationServiceError {
            #expect(error == expectedError)
        } catch {
            Issue.record(
                "Unexpected error: \(error)"
            )
        }
    }
}
