//
//  LoginEndpoint.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation

nonisolated struct LoginRequest: Encodable, Sendable {
    let login: String
    let password: String
}

nonisolated struct AuthenticationResponse:
    Decodable,
    Sendable,
    Equatable
{
    let accessToken: String
    let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

nonisolated enum LoginEndpoint {
    static func login(
        login: String,
        password: String
    ) -> Endpoint<LoginRequest, AuthenticationResponse> {
        Endpoint(
            method: .post,
            path: ["api", "v1", "auth", "login"],
            body: LoginRequest(
                login: login,
                password: password
            )
        )
    }
}
