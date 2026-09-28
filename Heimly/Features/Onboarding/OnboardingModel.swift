//
//  OnboardingModel.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 28.09.2026.
//

import Foundation

@MainActor
@Observable
final class OnboardingModel {
    enum Step: Equatable {
        case serverConnection
        case authentication
    }
    
    private(set) var step: Step
    private(set) var serverURL: URL?
    
    private let serverURLStore: any ServerURLStoring
    
    init(
        serverURLStore: any ServerURLStoring =
        UserDefaultsServerURLStore()
    ) {
        self.serverURLStore = serverURLStore
        
        let storedServerURL = serverURLStore.serverURL
        serverURL = storedServerURL
        step = storedServerURL == nil
            ? .serverConnection
            : .authentication
    }
    
    func didConnect(to serverURL: URL) {
        serverURLStore.save(serverURL)

        self.serverURL = serverURL
        step = .authentication
    }
}
