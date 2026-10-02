//
//  UserDefaultsSelectedAccountStoreTests.swift
//  HeimlyTests
//
//  Created by Codex on 01.10.2026.
//

import Foundation
import Testing
@testable import Heimly

struct UserDefaultsSelectedAccountStoreTests {
    @Test
    func selectsReloadsAndClearsAccount() throws {
        let suiteName = "UserDefaultsSelectedAccountStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsSelectedAccountStore(defaults: defaults)
        let serverURL = try #require(URL(string: "https://example.heimly.space"))
        let userID = UUID()

        #expect(store.selectedUserID(for: serverURL) == nil)

        store.select(userID: userID, for: serverURL)

        let reloadedDefaults = try #require(UserDefaults(suiteName: suiteName))
        let reloadedStore = UserDefaultsSelectedAccountStore(defaults: reloadedDefaults)

        #expect(reloadedStore.selectedUserID(for: serverURL) == userID)

        reloadedStore.clearSelection(for: serverURL)

        #expect(reloadedStore.selectedUserID(for: serverURL) == nil)
    }

    @Test
    func keepsSelectionsScopedByServer() throws {
        let suiteName = "UserDefaultsSelectedAccountStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDefaultsSelectedAccountStore(defaults: defaults)
        let firstServerURL = try #require(URL(string: "https://one.heimly.space"))
        let secondServerURL = try #require(URL(string: "https://two.heimly.space"))
        let firstUserID = UUID()
        let secondUserID = UUID()

        store.select(userID: firstUserID, for: firstServerURL)
        store.select(userID: secondUserID, for: secondServerURL)

        #expect(store.selectedUserID(for: firstServerURL) == firstUserID)
        #expect(store.selectedUserID(for: secondServerURL) == secondUserID)

        store.clearSelection(for: firstServerURL)

        #expect(store.selectedUserID(for: firstServerURL) == nil)
        #expect(store.selectedUserID(for: secondServerURL) == secondUserID)
    }

    @Test
    func treatsMalformedStoredIdentifierAsNoSelection() throws {
        let suiteName = "UserDefaultsSelectedAccountStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let serverURL = try #require(URL(string: "https://example.heimly.space"))
        defaults.set(
            "not-a-uuid",
            forKey: "selectedAuthenticationAccount.\(serverURL.absoluteString)"
        )

        let store = UserDefaultsSelectedAccountStore(defaults: defaults)

        #expect(store.selectedUserID(for: serverURL) == nil)
    }
}
