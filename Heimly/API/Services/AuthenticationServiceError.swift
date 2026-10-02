//
//  AuthenticationServiceError.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation

nonisolated enum AuthenticationServiceError:
    Error,
    Sendable,
    Equatable
{
    case invalidRequest
    case invalidCredentials
    case serverUnavailable
    case incompatibleServer
    case unexpected
}
