//
//  APIClient.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation

nonisolated struct APIClient: Sendable {
    private let baseURL: URL
    private let httpClient: any HTTPClient
    
    init(
        baseURL: URL,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
    }
    
    func send<Request, Response>(
        _ endpoint: Endpoint<Request, Response>
    ) async throws -> Response
    where
    Request: Encodable & Sendable,
    Response: Decodable & Sendable
    {
        let request = try makeRequest(for: endpoint)
        let response = try await httpClient.send(request)
        
        guard endpoint.successfulStatusCodes.contains(response.statusCode) else {
            throw APIError.unacceptableStatusCode(
                code: response.statusCode,
                body: response.data
            )
        }
        
        do {
            return try JSONDecoder().decode(Response.self, from: response.data)
        } catch {
            throw APIError.responseDecodingFailed(underlying: error)
        }
    }
    
    private func makeRequest<Request, Response>(
        for endpoint: Endpoint<Request, Response>
    ) throws -> URLRequest
    where Request: Encodable & Sendable,
          Response: Decodable & Sendable
    {
        var url = baseURL
        
        for component in endpoint.path {
            url.appendPathComponent(component)
        }
        
        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        
        components.fragment = nil
        components.queryItems = endpoint.queryItems.isEmpty
            ? nil
            : endpoint.queryItems
        
        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        
        if let body = endpoint.body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
                request.setValue(
                    "application/json",
                    forHTTPHeaderField: "Content-Type"
                )
            } catch {
                throw APIError.requestEncodingFailed(underlying: error)
            }
        }
        
        for (name, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        
        return request
    }
}
