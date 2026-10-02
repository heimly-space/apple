//
//  AuthenticatedSession.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 30.09.2026.
//

import Foundation

nonisolated struct AuthenticatedSession:
    Sendable,
    Equatable
{
    let userID: UUID
    let tokens: AuthenticationTokens
}
