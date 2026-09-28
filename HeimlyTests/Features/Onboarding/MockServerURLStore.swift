//
//  MockServerURLStore.swift
//  HeimlyTests
//
//  Created by Georgy Dzutsev on 28.09.2026.
//

import Foundation
@testable import Heimly

nonisolated final class MockServerURLStore: ServerURLStoring {
    var serverURL: URL?
    
    init(serverURL: URL? = nil) {
        self.serverURL = serverURL
    }
    
    func save(_ serverURL: URL) {
        self.serverURL = serverURL
    }
    
    func remove() {
        self.serverURL = nil
    }
}
