//
//  AuthenticationModelTests.swift
//  HeimlyTests
//
//  Created by Codex on 01.10.2026.
//

import Foundation
import Testing
@testable import Heimly

@MainActor
struct AuthenticationModelTests {
    @Test
    func signsInPersistsSessionAndSelectsAccount() async throws {
        let serverURL = try #require(URL(string: "https://example.com"))
        let userID = UUID()
        let tokens = AuthenticationTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token"
        )
        let session = AuthenticatedSession(userID: userID, tokens: tokens)

        let authenticator = MockAuthenticator { receivedURL, login, password in
            #expect(receivedURL == serverURL)
            #expect(login == "alice")
            #expect(password == "secret")
            return session
        }
        let tokensStore = MockAuthenticationTokensStore { receivedTokens, receivedURL, receivedUserID in
            #expect(receivedTokens == tokens)
            #expect(receivedURL == serverURL)
            #expect(receivedUserID == userID)
        }
        let selectedAccountStore = MockSelectedAccountStore { receivedUserID, receivedURL in
            #expect(receivedUserID == userID)
            #expect(receivedURL == serverURL)
        }
        let model = AuthenticationModel(
            serverURL: serverURL,
            authenticator: authenticator,
            tokensStore: tokensStore,
            selectedAccountStore: selectedAccountStore
        )
        model.login = "  alice  "
        model.password = "secret"

        await model.signIn()

        #expect(model.state == .authenticated(userID: userID))
        #expect(model.password.isEmpty)
        #expect(!model.canSignIn)
    }

    @Test
    func requiresLoginAndPassword() throws {
        let serverURL = try #require(URL(string: "https://example.com"))
        let model = AuthenticationModel(
            serverURL: serverURL,
            authenticator: MockAuthenticator { _, _, _ in
                Issue.record("Authentication should not start")
                throw TestError.unexpectedCall
            },
            tokensStore: MockAuthenticationTokensStore(),
            selectedAccountStore: MockSelectedAccountStore()
        )

        #expect(!model.canSignIn)

        model.login = "alice"
        #expect(!model.canSignIn)

        model.login = "   "
        model.password = "secret"
        #expect(!model.canSignIn)

        model.login = "alice"
        #expect(model.canSignIn)
    }

    @Test
    func exposesAuthenticationFailureWithoutPersistingSession() async throws {
        let serverURL = try #require(URL(string: "https://example.com"))
        let model = AuthenticationModel(
            serverURL: serverURL,
            authenticator: MockAuthenticator { _, _, _ in
                throw AuthenticationServiceError.invalidCredentials
            },
            tokensStore: MockAuthenticationTokensStore { _, _, _ in
                Issue.record("Tokens should not be saved")
            },
            selectedAccountStore: MockSelectedAccountStore { _, _ in
                Issue.record("Account should not be selected")
            }
        )
        model.login = "alice"
        model.password = "wrong-password"

        await model.signIn()

        #expect(
            model.state
                == .failed(.authentication(.invalidCredentials))
        )
        #expect(model.password == "wrong-password")
        #expect(model.canSignIn)
    }

    @Test
    func doesNotSelectAccountWhenTokenPersistenceFails() async throws {
        let serverURL = try #require(URL(string: "https://example.com"))
        let session = AuthenticatedSession(
            userID: UUID(),
            tokens: AuthenticationTokens(
                accessToken: "access-token",
                refreshToken: "refresh-token"
            )
        )
        let model = AuthenticationModel(
            serverURL: serverURL,
            authenticator: MockAuthenticator { _, _, _ in session },
            tokensStore: MockAuthenticationTokensStore { _, _, _ in
                throw TestError.persistenceFailed
            },
            selectedAccountStore: MockSelectedAccountStore { _, _ in
                Issue.record("Account should not be selected")
            }
        )
        model.login = "alice"
        model.password = "secret"

        await model.signIn()

        #expect(model.state == .failed(.sessionPersistenceFailed))
        #expect(model.password == "secret")
        #expect(model.canSignIn)
    }

    @Test
    func clearsAuthenticationFailure() async throws {
        let serverURL = try #require(URL(string: "https://example.com"))
        let model = AuthenticationModel(
            serverURL: serverURL,
            authenticator: MockAuthenticator { _, _, _ in
                throw AuthenticationServiceError.invalidCredentials
            },
            tokensStore: MockAuthenticationTokensStore(),
            selectedAccountStore: MockSelectedAccountStore()
        )
        model.login = "alice"
        model.password = "wrong-password"

        await model.signIn()
        #expect(
            model.state
                == .failed(.authentication(.invalidCredentials))
        )

        model.clearFailure()

        #expect(model.state == .idle)
    }

    @Test
    func cancellationReturnsToIdleWithoutPersistingSession() async throws {
        let serverURL = try #require(URL(string: "https://example.com"))
        let session = AuthenticatedSession(
            userID: UUID(),
            tokens: AuthenticationTokens(
                accessToken: "access-token",
                refreshToken: "refresh-token"
            )
        )
        let model = AuthenticationModel(
            serverURL: serverURL,
            authenticator: MockAuthenticator { _, _, _ in
                while !Task.isCancelled {
                    await Task.yield()
                }
                return session
            },
            tokensStore: MockAuthenticationTokensStore { _, _, _ in
                Issue.record("Tokens should not be saved")
            },
            selectedAccountStore: MockSelectedAccountStore { _, _ in
                Issue.record("Account should not be selected")
            }
        )
        model.login = "alice"
        model.password = "secret"

        let task = Task {
            await model.signIn()
        }

        while model.state != .signingIn {
            await Task.yield()
        }

        task.cancel()
        await task.value

        #expect(model.state == .idle)
        #expect(model.password == "secret")
        #expect(model.canSignIn)
    }
}

private nonisolated struct MockAuthenticator: Authenticating {
    let handler: @Sendable (URL, String, String) async throws
        -> AuthenticatedSession

    func signIn(
        to serverURL: URL,
        login: String,
        password: String
    ) async throws -> AuthenticatedSession {
        try await handler(serverURL, login, password)
    }
}

private nonisolated struct MockAuthenticationTokensStore:
    AuthenticationTokensStoring
{
    let saveHandler: @Sendable (
        AuthenticationTokens,
        URL,
        UUID
    ) throws -> Void

    init(
        saveHandler: @escaping @Sendable (
            AuthenticationTokens,
            URL,
            UUID
        ) throws -> Void = { _, _, _ in }
    ) {
        self.saveHandler = saveHandler
    }

    func tokens(
        for serverURL: URL,
        userID: UUID
    ) throws -> AuthenticationTokens? {
        nil
    }

    func save(
        _ tokens: AuthenticationTokens,
        for serverURL: URL,
        userID: UUID
    ) throws {
        try saveHandler(tokens, serverURL, userID)
    }

    func removeTokens(
        for serverURL: URL,
        userID: UUID
    ) throws {}
}

private nonisolated struct MockSelectedAccountStore:
    SelectedAccountStoring
{
    let selectHandler: @Sendable (UUID, URL) -> Void

    init(
        selectHandler: @escaping @Sendable (UUID, URL) -> Void =
            { _, _ in }
    ) {
        self.selectHandler = selectHandler
    }

    func selectedUserID(for serverURL: URL) -> UUID? {
        nil
    }

    func select(userID: UUID, for serverURL: URL) {
        selectHandler(userID, serverURL)
    }

    func clearSelection(for serverURL: URL) {}
}

private nonisolated enum TestError: Error {
    case persistenceFailed
    case unexpectedCall
}
