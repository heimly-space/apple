//
//  APIError.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation

nonisolated enum APIError: Error, Sendable {
    case invalidURL
    case requestEncodingFailed(underlying: any Error)
    case unacceptableStatusCode(code: Int, body: Data)
    case responseDecodingFailed(underlying: any Error)
}
