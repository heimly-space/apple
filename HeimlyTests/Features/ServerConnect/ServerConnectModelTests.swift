//
//  ServerConnectModelTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation
import Testing
@testable import Heimly

@MainActor
struct ServerConnectModelTests {
    @Test
    func succeedsAfterServerVerification() async throws {
        let expectedURL = try #require(
            URL(string: "https://example.com")
        )
        
        let connector = MockServerConnector { receivedURL in
            #expect(receivedURL == expectedURL)
        }
        
        let model = ServerConnectModel(
            serverConnector: connector
        )
        
        let succeeded = await model.connect(to: expectedURL)
        
        #expect(succeeded)
        #expect(model.state == .idle)
    }
    
    @Test
    func mapsTimeoutFailure() async throws {
        let connector = MockServerConnector { _ in
            throw URLError(.timedOut)
        }
        
        let model = ServerConnectModel(
            serverConnector: connector
        )
        
        let url = try #require(URL(string: "https://example.com"))
        
        let succeeded = await model.connect(to: url)
        
        #expect(!succeeded)
        #expect(model.state == .failed(.timedOut))
    }
    
    @Test
    func mapsUnhealthyServerFailure() async throws {
        let connector = MockServerConnector { _ in
            throw ServerConnectionError.unhealthy(
                status: "maintenance"
            )
        }

        let model = ServerConnectModel(
            serverConnector: connector
        )

        let url = try #require(
            URL(string: "https://example.com")
        )

        let succeeded = await model.connect(to: url)

        #expect(!succeeded)
        #expect(model.state == .failed(.serverUnavailable))
    }
    
    @Test
    func clearsPreviousFailure() async throws {
        let connector = MockServerConnector { _ in
            throw URLError(.timedOut)
        }

        let model = ServerConnectModel(
            serverConnector: connector
        )

        let url = try #require(
            URL(string: "https://example.com")
        )

        _ = await model.connect(to: url)
        #expect(model.failure == .timedOut)

        model.clearFailure()

        #expect(model.state == .idle)
    }
    
    @Test
    func cancellationReturnsToIdle() async throws {
        let connector = MockServerConnector { _ in
            while !Task.isCancelled {
                await Task.yield()
            }
            
            // Deliberately return successfully instead of throwing.
        }
        
        let model = ServerConnectModel(
            serverConnector: connector
        )
        
        let url = try #require(
            URL(string: "https://example.com")
        )
        
        let connectionTask = Task {
            await model.connect(to: url)
        }
        
        while !model.isConnecting {
            await Task.yield()
        }
        
        connectionTask.cancel()
        
        let succeeded = await connectionTask.value
        
        #expect(!succeeded)
        #expect(model.state == .idle)
    }
    
    @Test
    func rejectsSecondConnectionWhileConnecting() async throws {
        let connector = MockServerConnector { _ in
            while !Task.isCancelled {
                await Task.yield()
            }
        }
        
        let model = ServerConnectModel(
            serverConnector: connector
        )
        
        let url = try #require(
            URL(string: "https://example.com")
        )
        
        let firstConnection = Task {
            await model.connect(to: url)
        }
        
        while !model.isConnecting {
            await Task.yield()
        }
        
        let secondSucceeded = await model.connect(to: url)
        
        #expect(!secondSucceeded)
        #expect(model.state == .connecting)
        
        firstConnection.cancel()
        _ = await firstConnection.value
        
        #expect(model.state == .idle)
    }
    
    @Test
    func mapsNoInternetFailure() async throws {
        let connector = MockServerConnector { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        let model = ServerConnectModel(
            serverConnector: connector
        )
        
        let url = try #require(
            URL(string: "https://example.com")
        )
        
        let succeeded = await model.connect(to: url)
        
        #expect(!succeeded)
        #expect(model.state == .failed(.noInternetConnection))
    }
}
