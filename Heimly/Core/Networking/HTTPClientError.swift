//
//  HTTPClientError.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation

nonisolated enum HTTPClientError: Error, Sendable {
    case nonHTTPResponse
}
