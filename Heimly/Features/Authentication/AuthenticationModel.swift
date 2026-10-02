//
//  AuthenticationModel.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 01.10.2026.
//

import Foundation

@MainActor
@Observable
final class AuthenticationModel {
    enum Failure: Equatable {
        case authentication(AuthenticationServiceError)
        case sessionPersistenceFailed
    }
    
    enum State: Equatable {
        case idle
        case signingIn
        case authenticated(userID: UUID)
        case failed(Failure)
    }
    
    private(set) var state: State = .idle
    
    var login = ""
    var password = ""
    
    var canSignIn: Bool {
        let hasCredentials =
        !login.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !password.isEmpty
        
        switch state {
        case .idle, .failed:
            return hasCredentials
        case .signingIn, .authenticated:
            return false
        }
    }
    
    private let serverURL: URL
    private let authenticator: any Authenticating
    private let tokensStore: any AuthenticationTokensStoring
    private let selectedAccountStore: any SelectedAccountStoring
    
    init(
        serverURL: URL,
        authenticator: any Authenticating = AuthenticationService(),
        tokensStore: any AuthenticationTokensStoring = KeychainAuthenticationTokensStore(),
        selectedAccountStore: any SelectedAccountStoring =
        UserDefaultsSelectedAccountStore()
    ) {
        self.serverURL = serverURL
        self.authenticator = authenticator
        self.tokensStore = tokensStore
        self.selectedAccountStore = selectedAccountStore
    }
    
    func clearFailure() {
        guard case .failed = state else {
            return
        }
        
        state = .idle
    }
    
    func signIn() async {
        guard canSignIn else {
            return
        }
        
        state = .signingIn
        
        let submittedLogin = login.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let session: AuthenticatedSession
        
        do {
            session = try await authenticator.signIn(
                to: serverURL,
                login: submittedLogin,
                password: password
            )
            
            try Task.checkCancellation()
        } catch is CancellationError {
            state = .idle
            return
        } catch let error as AuthenticationServiceError {
            state = .failed(.authentication(error))
            return
        } catch {
            state = .failed(.authentication(.unexpected))
            return
        }

        do {
            try tokensStore.save(
                session.tokens,
                for: serverURL,
                userID: session.userID
            )
        } catch {
            state = .failed(.sessionPersistenceFailed)
            return
        }

        selectedAccountStore.select(
            userID: session.userID,
            for: serverURL
        )

        password = ""
        state = .authenticated(userID: session.userID)
    }
}
