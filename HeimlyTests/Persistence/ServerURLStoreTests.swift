//
//  ServerURLStoreTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 28.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct ServerURLStoreTests {
    @Test
    func savesLoadsAndRemovesServerURL() throws {
        let suiteName = "ServerURLStoreTests.\(UUID().uuidString)"
        
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        
        let store = UserDefaultsServerURLStore(
            defaults: defaults
        )
        
        let expectedURL = try #require(
            URL(string: "https://example.heimly.space")
        )
        
        #expect(store.serverURL == nil)

        store.save(expectedURL)

        let reloadedDefaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let reloadedStore = UserDefaultsServerURLStore(
            defaults: reloadedDefaults
        )

        #expect(reloadedStore.serverURL == expectedURL)

        reloadedStore.remove()

        #expect(reloadedStore.serverURL == nil)
    }
}
