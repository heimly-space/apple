//
//  UserDefaultsSelectedAccountStore.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 01.10.2026.
//

import Foundation

nonisolated struct UserDefaultsSelectedAccountStore: SelectedAccountStoring {
    private enum Key {
        static let prefix = "selectedAuthenticationAccount."
    }
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func selectedUserID(for serverURL: URL) -> UUID? {
        defaults.string(forKey: key(for: serverURL))
            .flatMap(UUID.init(uuidString:))
    }
    
    func select(userID: UUID, for serverURL: URL) {
        defaults.set(userID.uuidString, forKey: key(for: serverURL))
    }
    
    func clearSelection(for serverURL: URL) {
        defaults.removeObject(forKey: key(for: serverURL))
    }
    
    private func key(for serverURL: URL) -> String {
        Key.prefix + serverURL.absoluteString
    }
}
