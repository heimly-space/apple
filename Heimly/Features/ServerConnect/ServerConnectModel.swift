//
//  ServerConnectModel.swift
//  Heimly
//
//  Created by Georgy Dzutsev on 25.09.2026.
//

import Foundation

@MainActor
@Observable
final class ServerConnectModel {
    enum Failure: Equatable {
        case noInternetConnection
        case serverNotFound
        case timedOut
        case incompatibleServer
        case serverUnavailable
        case secureConnectionFailed
        case unknown
    }
    
    enum State: Equatable {
        case idle
        case connecting
        case failed(Failure)
    }
    
    private(set) var state: State = .idle
    
    private let serverConnector: any ServerConnecting
    
    init(
        serverConnector: any ServerConnecting =
            ServerConnectionService()
    ) {
        self.serverConnector = serverConnector
    }
    
    var isConnecting: Bool {
        state == .connecting
    }
    
    var failure: Failure? {
        guard case .failed(let failure) = state else {
            return nil
        }
        
        return failure
    }
    
    func clearFailure() {
        guard case .failed = state else {
            return
        }
        
        state = .idle
    }
    
    func connect(to serverURL: URL) async -> Bool {
        guard !isConnecting else {
            return false
        }
        
        state = .connecting
        
        do {
            try await serverConnector.verifyServer(at: serverURL)
            try Task.checkCancellation()
            
            state = .idle
            return true
        } catch is CancellationError {
            state = .idle
            return false
        } catch let error as URLError where error.code == .cancelled {
            state = .idle
            return false
        } catch let error as URLError {
            state = .failed(map(error))
            return false
        } catch is ServerConnectionError {
            state = .failed(.serverUnavailable)
            return false
        } catch let error as APIError {
            state = .failed(map(error))
            return false
        } catch {
            state = .failed(.unknown)
            return false
        }
    }
    
    private func map(_ error: URLError) -> Failure {
        switch error.code {
        case .notConnectedToInternet:
            return .noInternetConnection
            
        case .cannotFindHost,
                .cannotConnectToHost,
                .dnsLookupFailed:
            return .serverNotFound
            
        case .timedOut:
            return .timedOut
            
        case .secureConnectionFailed,
                .serverCertificateHasBadDate,
                .serverCertificateUntrusted,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid:
            return .secureConnectionFailed
            
        default:
            return .unknown
        }
    }
    
    private func map(_ error: APIError) -> Failure {
        switch error {
        case .unacceptableStatusCode(let code, _):
            return code >= 500
                ? .serverUnavailable
                : .incompatibleServer
            
        case .responseDecodingFailed:
            return .incompatibleServer
            
        case .invalidURL,
                .requestEncodingFailed:
            return .unknown
        }
    }
}
