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

        #expect(model.step == .authentication(serverURL: storedURL))
    }
    
    @Test
    func advancesFromAuthenticationToHouseholdSelection() throws {
        let serverURL = try #require(
            URL(string: "https://example.heimly.space")
        )
        let userID = UUID()
        let model = OnboardingModel(
            serverURLStore: MockServerURLStore(
                serverURL: serverURL
            )
        )

        #expect(model.authenticationModel != nil)

        model.didAuthenticate(userID: userID)

        #expect(
            model.step
                == .householdSelection(
                    serverURL: serverURL,
                    userID: userID
                )
        )
        #expect(model.authenticationModel == nil)
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
        #expect(model.step == .authentication(serverURL: connectedURL))
    }
}
