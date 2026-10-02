//
//  AuthenticationService.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation

nonisolated protocol Authenticating: Sendable {
    func signIn(
        to serverURL: URL,
        login: String,
        password: String
    ) async throws -> AuthenticatedSession
}

nonisolated struct AuthenticationService: Authenticating {
    private let httpClient: any HTTPClient
    
    init(
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        self.httpClient = httpClient
    }
    
    func signIn(
        to serverURL: URL,
        login: String,
        password: String
    ) async throws -> AuthenticatedSession {
        let apiClient = APIClient(
            baseURL: serverURL,
            httpClient: httpClient
        )
        
        do {
            let loginResponse = try await apiClient.send(
                LoginEndpoint.login(
                    login: login,
                    password: password
                )
            )
            
            let tokens = AuthenticationTokens(
                accessToken: loginResponse.accessToken,
                refreshToken: loginResponse.refreshToken
            )
            
            let currentUser = try await apiClient.send(
                CurrentUserEndpoint.get(
                    accessToken: tokens.accessToken
                )
            )
            
            return AuthenticatedSession(
                userID: currentUser.id,
                tokens: tokens
            )
        } catch let error as APIError {
            throw map(error)
        } catch is HTTPClientError {
            throw AuthenticationServiceError.incompatibleServer
        }
    }
    
    private func map(
        _ error: APIError
    ) -> AuthenticationServiceError {
        switch error {
        case .unacceptableStatusCode(let code, _):
            switch code {
            case 400:
                return .invalidRequest
                
            case 401:
                return .invalidCredentials
                
            case 404:
                return .incompatibleServer
                
            case 500..<600:
                return .serverUnavailable
                
            default:
                return .unexpected
            }
            
        case .responseDecodingFailed:
            return .incompatibleServer
            
        case .invalidURL,
                .requestEncodingFailed:
            return .unexpected
        }
    }
}
