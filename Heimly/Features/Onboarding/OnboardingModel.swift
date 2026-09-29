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
        case authentication(serverURL: URL)
    }
    
    private(set) var step: Step
    
    private let serverURLStore: any ServerURLStoring
    
    init(
        serverURLStore: any ServerURLStoring =
        UserDefaultsServerURLStore()
    ) {
        self.serverURLStore = serverURLStore
        
        if let storedServerURL = serverURLStore.serverURL {
            step = .authentication(
                serverURL: storedServerURL
            )
        } else {
            step = .serverConnection
        }
    }
    
    func didConnect(to serverURL: URL) {
        serverURLStore.save(serverURL)

        step = .authentication(serverURL: serverURL)
    }
    
    func chooseAnotherServer() {
        serverURLStore.remove()
        
        step = .serverConnection
    }
}
