//
//  AuthenticationView.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 02.10.2026.
//

import SwiftUI

struct AuthenticationView: View {
    let model: AuthenticationModel
    let onAuthenticated: (UUID) -> Void
    let onChangeServer: () -> Void
    
    @State private var signInTask: Task<Void, Never>?
    
    private var failureMessage: LocalizedStringResource? {
        guard case .failed(let failure) = model.state else {
            return nil
        }
        
        switch failure {
        case .authentication(let error):
            switch error {
            case .invalidRequest:
                return .authenticationErrorInvalidRequest
            case .invalidCredentials:
                return .authenticationErrorInvalidCredentials
            case .serverUnavailable:
                return .authenticationErrorServerUnavailable
                
            case .incompatibleServer:
                return .authenticationErrorIncompatibleServer
                
            case .unexpected:
                return .authenticationErrorUnexpected
            }
            
        case .sessionPersistenceFailed:
            return .authenticationErrorSessionPersistence
        }
    }
    
    var body: some View {
        @Bindable var model = model
        
        VStack {
            AuthenticationHeader()
            
            VStack(spacing: 16) {
                AuthenticationForm(
                    login: $model.login,
                    password: $model.password,
                    isDisabled: model.state == .signingIn,
                    onSubmit: signIn,
                    onInputChanged: model.clearFailure
                )
                
                if let failureMessage {
                    AuthenticationFailureView(
                        message: failureMessage
                    )
                }
                
                AuthenticationActions(
                    canSignIn: model.canSignIn,
                    isSigningIn: model.state == .signingIn,
                    onSignIn: signIn,
                    onChangeServer: onChangeServer
                )
            }
            .padding(.top, 20)
        }
        .padding(28)
        .padding()
        .onDisappear {
            signInTask?.cancel()
            signInTask = nil
        }
    }
    
    private func signIn() {
        guard signInTask == nil else {
            return
        }
        
        signInTask = Task {
            defer {
                signInTask = nil
            }
            
            await model.signIn()
            
            if case .authenticated(let userID) = model.state {
                onAuthenticated(userID)
            }
        }
    }
}

private struct AuthenticationForm: View {
    @Binding var login: String
    @Binding var password: String
    
    let isDisabled: Bool
    let onSubmit: () -> Void
    let onInputChanged: () -> Void
    
    private enum Field: Hashable {
        case login
        case password
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack(
            spacing: 16
        ) {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text(.authenticationLoginLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField(
                    text: $login,
                    prompt: Text(.authenticationLoginPrompt),
                    label: {
                        Text(.authenticationLoginLabel)
                    }
                )
                .labelsHidden()
                .textFieldStyle(.bordered)
                .textContentType(.username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disabled(isDisabled)
                .focused($focusedField, equals: .login)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
                .onChange(of: login) {
                    onInputChanged()
                }
            }
            
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text(.authenticationPasswordLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                SecureField(
                    text: $password,
                    prompt: Text(.authenticationPasswordPrompt),
                    label: {
                        Text(.authenticationPasswordLabel)
                    }
                )
                .labelsHidden()
                .textFieldStyle(.bordered)
                .textContentType(.password)
                .disabled(isDisabled)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    focusedField = nil
                    onSubmit()
                }
                .onChange(of: password) { onInputChanged()
                }
            }
        }
    }
}

private struct AuthenticationActions: View {
    let canSignIn: Bool
    let isSigningIn: Bool
    let onSignIn: () -> Void
    let onChangeServer: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSignIn) {
                if isSigningIn {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(
                            Text(.authenticationSigningIn)
                        )
                } else {
                    Text(.authenticationButtonSignIn)
                }
            }
            .disabled(!canSignIn)
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.large)
            
            Button(
                .authenticationButtonChangeServer,
                action: onChangeServer
            )
            .disabled(isSigningIn)
        }
    }
}

private struct AuthenticationFailureView: View {
    let message: LocalizedStringResource
    
    var body: some View {
        Label(
            message,
            systemImage: "exclamationmark.circle.fill"
        )
        .font(.caption)
        .foregroundStyle(.red)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

private struct AuthenticationHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 32))
                .padding(.bottom, 6)
                .foregroundStyle(.tint)
            
            Text(.authenticationTitle)
                .font(.title.weight(.semibold))
            
            Text(.authenticationSubtitle)
        }
    }
}

#Preview {
    if let serverURL = URL(string: "https://example.heimly.space") {
        AuthenticationView(
            model: AuthenticationModel(serverURL: serverURL),
            onAuthenticated: { _ in },
            onChangeServer: {},
        )
    }
}
