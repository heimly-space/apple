//
//  AuthenticationTokens.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation

nonisolated struct AuthenticationTokens:
    Sendable,
    Equatable
{
    let accessToken: String
    let refreshToken: String
}
