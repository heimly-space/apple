//
//  KeychainAuthenticationTokensStoreTests.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 30.09.2026.
//

import Foundation
import Testing
@testable import Heimly

struct KeychainAuthenticationTokensStoreTests {
    @Test
    func storesUpdatesScopesAndRemovesTokens() throws {
        let store = KeychainAuthenticationTokensStore()

        let serverID = UUID().uuidString.lowercased()
        let firstServerURL = try #require(
            URL(string: "https://\(serverID).invalid/heimly")
        )
        let secondServerURL = try #require(
            URL(string: "https://\(serverID).invalid/another")
        )

        let firstUserID = UUID()
        let secondUserID = UUID()

        defer {
            try? store.removeTokens(
                for: firstServerURL,
                userID: firstUserID
            )
            try? store.removeTokens(
                for: firstServerURL,
                userID: secondUserID
            )
            try? store.removeTokens(
                for: secondServerURL,
                userID: firstUserID
            )
        }

        #expect(
            try store.tokens(
                for: firstServerURL,
                userID: firstUserID
            ) == nil
        )

        let initialTokens = AuthenticationTokens(
            accessToken: "access-1",
            refreshToken: "refresh-1"
        )

        try store.save(
            initialTokens,
            for: firstServerURL,
            userID: firstUserID
        )

        #expect(
            try store.tokens(
                for: firstServerURL,
                userID: firstUserID
            ) == initialTokens
        )

        let updatedTokens = AuthenticationTokens(
            accessToken: "access-2",
            refreshToken: "refresh-2"
        )

        try store.save(
            updatedTokens,
            for: firstServerURL,
            userID: firstUserID
        )

        #expect(
            try store.tokens(
                for: firstServerURL,
                userID: firstUserID
            ) == updatedTokens
        )

        #expect(
            try store.tokens(
                for: firstServerURL,
                userID: secondUserID
            ) == nil
        )
        #expect(
            try store.tokens(
                for: secondServerURL,
                userID: firstUserID
            ) == nil
        )

        try store.removeTokens(
            for: firstServerURL,
            userID: firstUserID
        )

        #expect(
            try store.tokens(
                for: firstServerURL,
                userID: firstUserID
            ) == nil
        )

        // Removing an already absent item must remain safe.
        try store.removeTokens(
            for: firstServerURL,
            userID: firstUserID
        )
    }
}
