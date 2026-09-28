//
//  OnboardingModelTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 28.09.2026.
//

import Foundation
import Testing
@testable import Heimly

@MainActor
struct OnboardingModelTests {
    @Test
    func startsWithServerConnectionWithoutStoredURL() {
        let store = MockServerURLStore()
        
        let model = OnboardingModel(
            serverURLStore: store
        )
        
        #expect(model.step == .serverConnection)
        #expect(model.serverURL == nil)
    }
    
    @Test
    func restoresAuthenticationStepFromStoredURL() throws {
        let storedURL = try #require(
            URL(string: "https://example.heimly.space")
        )
        let store = MockServerURLStore(
            serverURL: storedURL
        )
        
        let model = OnboardingModel(
            serverURLStore: store
        )

        #expect(model.step == .authentication)
        #expect(model.serverURL == storedURL)
    }
    
    @Test
    func savesConnectedServerAndAdvancesToAuthentication() throws {
        let store = MockServerURLStore()
        let model = OnboardingModel(
            serverURLStore: store
        )

        let connectedURL = try #require(
            URL(string: "https://example.heimly.space")
        )

        model.didConnect(to: connectedURL)

        #expect(store.serverURL == connectedURL)
        #expect(model.serverURL == connectedURL)
        #expect(model.step == .authentication)
    }
}
