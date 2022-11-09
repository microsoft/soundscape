//
//  AuthorizationViewModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/**
 * `AuthorizationViewModel` is an observable wrapper for the given `AsyncAuthorizationProvider`
 */
class AuthorizationViewModel: ObservableObject, AuthorizationProvider {
    
    // MARK: Properties
    
    @Published private(set) var authorizationStatus: AuthorizationStatus
    
    let service: AuthorizedService
    private var provider: AsyncAuthorizationProvider
    
    // MARK: Initialization
    
    init(for service: AuthorizedService) {
        self.service = service
        
        switch service {
        case .location: provider = AppContext.shared.geolocationManager
        case .motion: provider = AppContext.shared.motionActivityContext
        }
        
        // Initialize published properties
        _authorizationStatus = .init(initialValue: provider.authorizationStatus)
        
        provider.authorizationDelegate = self
    }
    
    // MARK: -
    
    func requestAuthorization() {
        guard didRequestAuthorization == false else {
            return
        }
        
        provider.requestAuthorization()
        
        GDATelemetry.track("onboarding.authorization.request", with: ["service": service.rawValue])
    }
    
}

extension AuthorizationViewModel: AsyncAuthorizationProviderDelegate {
    
    func authorizationDidChange(_ authorization: AuthorizationStatus) {
        authorizationStatus = authorization
        
        GDATelemetry.track("onboarding.authorization.status_changed", with: ["service": service.rawValue, "status": authorizationStatus.rawValue])
    }
    
}
