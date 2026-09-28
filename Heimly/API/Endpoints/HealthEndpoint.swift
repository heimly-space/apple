//
//  HealthEndpoint.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 24.09.2026.
//

import Foundation

nonisolated enum HealthEndpoint {
    struct Response: Decodable, Sendable {
        let status: String
    }
    
    static let check = Endpoint<NoRequestBody, Response>(
        method: .get,
        path: ["health"]
    )
}
