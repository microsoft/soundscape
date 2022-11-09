//
//  AuthorizationItemView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct AuthorizationItemView: View {
    
    // MARK: Properties
    
    private let service: AuthorizedService
    private let status: AuthorizationStatus
    private let authorizedColor: Color
    private let deniedColor: Color
    
    @ViewBuilder
    private var serviceImage: some View {
        switch service {
        case .location:
            Image(systemName: "location")
        case .motion:
            Image(systemName: "figure.walk")
        }
    }
    
    @ViewBuilder
    private var leftAccessory: some View {
        switch status {
        case .authorized:
            Image(systemName: "checkmark")
                .foregroundColor(authorizedColor)
        case .denied:
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(deniedColor)
        case .notDetermined:
            serviceImage
        }
        
    }
    
    private var title: String {
        switch service {
        case .location:
            return GDLocalizedString("first_launch.permissions.location")
        case .motion:
            return GDLocalizedString("first_launch.permissions.motion")
        }
    }
    
    // MARK: Initialization
    
    init(service: AuthorizedService, status: AuthorizationStatus) {
        self.service = service
        self.status = status
        // Use default values
        self.authorizedColor = .green
        self.deniedColor = .red
    }
    
    private init(service: AuthorizedService, status: AuthorizationStatus, authorizedColor: Color, deniedColor: Color) {
        self.service = service
        self.status = status
        self.authorizedColor = authorizedColor
        self.deniedColor = deniedColor
    }
    
    // MARK: `body`
    
    var body: some View {
        HStack(spacing: 18.0) {
            leftAccessory
                .font(.headline)
                .accessibilityHidden(true)
            
            VStack(spacing: 4.0) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .accessibleTextFormat()
                
                GDLocalizedTextView("first_launch.permissions.required")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .accessibleTextFormat()
            }
        }
    }
    
}

struct AuthorizationItemView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingContainer {
            AuthorizationItemView(service: .location, status: .authorized)
            
            // Change authorized color
            AuthorizationItemView(service: .motion, status: .authorized)
                .authorizedColor(.orange)
            
            AuthorizationItemView(service: .location, status: .denied)
            
            // Change denied color
            AuthorizationItemView(service: .motion, status: .denied)
                .deniedColor(.orange)
            
            AuthorizationItemView(service: .location, status: .notDetermined)
            
            // Change foreground color
            AuthorizationItemView(service: .motion, status: .notDetermined)
                .foregroundColor(.green)
        }
        .foregroundColor(.primaryForeground)
    }
    
}

extension AuthorizationItemView {
    
    func authorizedColor(_ authorizedColor: Color) -> some View {
        AuthorizationItemView(service: self.service, status: self.status, authorizedColor: authorizedColor, deniedColor: self.deniedColor)
    }
    
    func deniedColor(_ deniedColor: Color) -> some View {
        AuthorizationItemView(service: self.service, status: self.status, authorizedColor: self.authorizedColor, deniedColor: deniedColor)
    }
    
}
