//
//  CurrentUserEndpoint.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 30.09.2026.
//

import Foundation

nonisolated struct CurrentUserResponse:
    Decodable,
    Sendable,
    Equatable
{
    let id: UUID
    let login: String
    let email: String
    let name: String
    let birthday: String?
}

nonisolated enum CurrentUserEndpoint {
    static func get(
        accessToken: String
    ) -> Endpoint<NoRequestBody, CurrentUserResponse> {
        Endpoint(
            method: .get,
            path: ["api", "v1", "users", "me"],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )
    }
}
