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
        case householdSelection(
            serverURL: URL,
            userID: UUID
        )
    }
    
    private(set) var step: Step
    private(set) var authenticationModel: AuthenticationModel?
    
    private let serverURLStore: any ServerURLStoring
    
    init(
        serverURLStore: any ServerURLStoring =
        UserDefaultsServerURLStore()
    ) {
        self.serverURLStore = serverURLStore
        
        if let storedServerURL = serverURLStore.serverURL {
            authenticationModel = AuthenticationModel(
                serverURL: storedServerURL
            )
            step = .authentication(
                serverURL: storedServerURL
            )
        } else {
            authenticationModel = nil
            step = .serverConnection
        }
    }
    
    func didConnect(to serverURL: URL) {
        serverURLStore.save(serverURL)

        authenticationModel = AuthenticationModel(serverURL: serverURL)
        step = .authentication(serverURL: serverURL)
    }
    
    func didAuthenticate(userID: UUID) {
        guard case .authentication(let serverURL) = step else {
            return
        }

        authenticationModel = nil
        step = .householdSelection(
            serverURL: serverURL,
            userID: userID
        )
    }
    
    func chooseAnotherServer() {
        serverURLStore.remove()
        
        authenticationModel = nil
        step = .serverConnection
    }
}
