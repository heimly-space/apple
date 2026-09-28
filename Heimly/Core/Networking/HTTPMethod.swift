//
//  HTTPMethod.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 24.09.2026.
//

nonisolated enum HTTPMethod: String, Sendable {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}
