//
//  KeychainAuthenticationTokensStore.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 29.09.2026.
//

import Foundation
import Security

nonisolated enum KeychainAuthenticationTokensStoreError:
    Error,
Sendable,
Equatable
{
    case encodingFailed
    case decodingFailed
    case invalidServerURL
    case unexpectedStatus(OSStatus)
}

nonisolated struct KeychainAuthenticationTokensStore:
    AuthenticationTokensStoring
{
    private struct StoredTokens: Codable {
        let accessToken: String
        let refreshToken: String
        
        init(_ tokens: AuthenticationTokens) {
            accessToken = tokens.accessToken
            refreshToken = tokens.refreshToken
        }
        
        var authenticationTokens: AuthenticationTokens {
            AuthenticationTokens(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        }
    }
    
    func tokens(
        for serverURL: URL,
        userID: UUID
    ) throws -> AuthenticationTokens? {
        var query = try baseQuery(
            for: serverURL,
            userID: userID
        )
        
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainAuthenticationTokensStoreError
                    .decodingFailed
            }
            
            do {
                return try JSONDecoder()
                    .decode(StoredTokens.self, from: data)
                    .authenticationTokens
            } catch {
                throw KeychainAuthenticationTokensStoreError
                    .decodingFailed
            }
            
        case errSecItemNotFound:
            return nil
            
        default:
            throw KeychainAuthenticationTokensStoreError
                .unexpectedStatus(status)
        }
    }
    
    func save(
        _ tokens: AuthenticationTokens,
        for serverURL: URL,
        userID: UUID
    ) throws {
        let data: Data
        
        do {
            data = try JSONEncoder().encode(
                StoredTokens(tokens)
            )
        } catch {
            throw KeychainAuthenticationTokensStoreError
                .encodingFailed
        }
        
        let query = try baseQuery(
            for: serverURL,
            userID: userID
        )
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )
        
        switch updateStatus {
        case errSecSuccess:
            return
            
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] =
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            
            let addStatus = SecItemAdd(
                addQuery as CFDictionary,
                nil
            )
            
            guard addStatus == errSecSuccess else {
                throw KeychainAuthenticationTokensStoreError
                    .unexpectedStatus(addStatus)
            }
            
        default:
            throw KeychainAuthenticationTokensStoreError
                .unexpectedStatus(updateStatus)
        }
    }
    
    func removeTokens(
        for serverURL: URL,
        userID: UUID
    ) throws {
        let query = try baseQuery(
            for: serverURL,
            userID: userID
        )
        
        let status = SecItemDelete(
            query as CFDictionary
        )
        
        switch status {
        case errSecSuccess,
            errSecItemNotFound:
            return
        default:
            throw KeychainAuthenticationTokensStoreError
                .unexpectedStatus(status)
        }
    }
    
    private func baseQuery(
        for serverURL: URL,
        userID: UUID
    ) throws -> [String: Any] {
        guard
            let host = serverURL.host,
            let scheme = serverURL.scheme?.lowercased()
                else {
            throw KeychainAuthenticationTokensStoreError
                .invalidServerURL
        }
        
        let internetProtocol: CFString
        
        switch scheme {
        case "https":
            internetProtocol = kSecAttrProtocolHTTPS
            
        case "http":
            internetProtocol = kSecAttrProtocolHTTP
            
        default:
            throw KeychainAuthenticationTokensStoreError
                .invalidServerURL
        }
        
        var query: [String: Any] = [
            kSecClass as String:
                kSecClassInternetPassword,
            kSecAttrAccount as String:
                userID.uuidString,
            kSecAttrServer as String:
                host.lowercased(),
            kSecAttrProtocol as String:
                internetProtocol,
            kSecAttrAuthenticationType as String:
                kSecAttrAuthenticationTypeDefault,
            kSecAttrPath as String:
                serverURL.path.isEmpty ? "/" : serverURL.path
        ]
        
        if let port = serverURL.port {
            query[kSecAttrPort as String] = port
        }
        
        return query
    }
}
