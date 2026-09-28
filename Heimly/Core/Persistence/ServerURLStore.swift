//
//  ServerURLStore.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 28.09.2026.
//

import Foundation

nonisolated protocol ServerURLStoring {
    var serverURL: URL? { get }
    
    func save(_ serverURL: URL)
    func remove()
}

nonisolated struct UserDefaultsServerURLStore: ServerURLStoring {
    private enum Key {
        static let serverURL = "selectedServerURL"
    }
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    var serverURL: URL? {
        defaults.string(forKey: Key.serverURL)
            .flatMap(URL.init(string:))
    }
    
    func save(_ serverURL: URL) {
        defaults.set(
            serverURL.absoluteString,
            forKey: Key.serverURL
        )
    }
    
    func remove() {
        defaults.removeObject(forKey: Key.serverURL)
    }
}
