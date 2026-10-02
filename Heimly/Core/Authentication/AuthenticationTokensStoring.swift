//
//  AuthenticationTokensStoring.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation

nonisolated protocol AuthenticationTokensStoring: Sendable {
    func tokens(
        for serverURL: URL,
        userID: UUID
    ) throws -> AuthenticationTokens?
    
    func save(
        _ tokens: AuthenticationTokens,
        for serverURL: URL,
        userID: UUID
    ) throws
    
    func removeTokens(
        for serverURL: URL,
        userID: UUID
    ) throws
}
