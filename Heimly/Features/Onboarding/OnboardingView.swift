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
        case .authentication(let serverURL):
            VStack(
                spacing: 8
            ) {
                Text(verbatim: serverURL.absoluteString)
                Button("Change server") {
                    model.chooseAnotherServer()
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
