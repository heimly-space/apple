//
//  ServerConnectView.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 22.09.2026.
//

import SwiftUI

struct ServerConnectView: View {
    
    let onConnect: (URL) -> Void
    
    @State private var serverAddress: String = ""
    @State private var didAttemptConnection = false
    @State private var model: ServerConnectModel
    @State private var connectionTask: Task<Void, Never>?
    
    init(
        model: ServerConnectModel = ServerConnectModel(),
        onConnect: @escaping (URL) -> Void
    ) {
        _model = State(initialValue: model)
        self.onConnect = onConnect
    }
    
    private var normalizedServerAddress: String {
        serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var serverURL: URL? {
        guard
            let url = URL(string: normalizedServerAddress),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
                else { return nil }
        
        return url
    }
    
    private var shouldShowInvalidAddress: Bool {
        didAttemptConnection
        && !normalizedServerAddress.isEmpty
        && serverURL == nil
    }
    
    private var connectionFailureMessage: LocalizedStringResource? {
        guard let failure = model.failure else {
            return nil
        }
        
        switch failure {
        case .noInternetConnection:
            return .serverConnectErrorNoInternet
            
        case .serverNotFound:
            return .serverConnectErrorServerNotFound
            
        case .timedOut:
            return .serverConnectErrorTimedOut
            
        case .incompatibleServer:
            return .serverConnectErrorIncompatible
            
        case .serverUnavailable:
            return .serverConnectErrorUnavailable
            
        case .secureConnectionFailed:
            return .serverConnectErrorSecureConnection
            
        case .unknown:
            return .serverConnectErrorUnknown
        }
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 6) {
                Image(systemName: "server.rack")
                    .font(.system(size: 32))
                    .padding(.bottom, 6)
                    .foregroundStyle(.tint)
                
                Text(.serverConnectTitle)
                    .font(.title.weight(.semibold))
            }
            
            VStack(spacing: 16) {
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Text(.serverConnectLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField(
                        text: $serverAddress,
                        prompt: Text(verbatim: "https://example.heimly.space"),
                        label: { Text(.serverConnectLabel) }
                    )
                    .disabled(model.isConnecting)
                    .textFieldStyle(.bordered)
                    .labelsHidden()
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onChange(of: serverAddress) {
                        model.clearFailure()
                    }
                    .onSubmit(connect)
#if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
#endif
                    
                    if shouldShowInvalidAddress {
                        Label(
                            .serverConnectLabelInvalidAddress,
                            systemImage: "exclamationmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                    
                    if let connectionFailureMessage {
                        Label(
                            connectionFailureMessage,
                            systemImage: "exclamationmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
                
                Button(action: connect) {
                    if model.isConnecting {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel(
                                Text(.serverConnectConnecting)
                            )
                    } else {
                        Text(.serverConnectButtonConnect)
                    }
                }
                .disabled(normalizedServerAddress.isEmpty ||
                          model.isConnecting)
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .controlSize(.large)
            }
            .padding(.top, 20)
        }
        .padding(28)
        .padding()
        .onDisappear {
            connectionTask?.cancel()
            connectionTask = nil
        }
    }
    
    private func connect() {
        didAttemptConnection = true
        
        guard
            let serverURL,
            !model.isConnecting
                else {
            return
        }
        
        connectionTask = Task {
            defer {
                connectionTask = nil
            }
            
            if await model.connect(to: serverURL) {
                onConnect(serverURL)
            }
        }
    }
}

#Preview {
    ServerConnectView { _ in }
}
