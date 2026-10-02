//
//  OnboardingView.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 28.09.2026.
//

import SwiftUI

struct OnboardingView: View {
    @State private var model = OnboardingModel()
    
    var body: some View {
        switch model.step {
        case .serverConnection:
            ServerConnectView { serverURL in
                model.didConnect(to: serverURL)
            }
        case .authentication:
            if let authenticationModel = model.authenticationModel {
                AuthenticationView(
                    model: authenticationModel,
                    onAuthenticated: { userID in
                        model.didAuthenticate(userID: userID)
                    },
                    onChangeServer: {
                        model.chooseAnotherServer()
                    }
                )
            }
        case .householdSelection(let serverURL, let userID):
            VStack(spacing: 8) {
                Text(verbatim: "Household selection")
                Text(verbatim: serverURL.absoluteString)
                Text(verbatim: userID.uuidString)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
