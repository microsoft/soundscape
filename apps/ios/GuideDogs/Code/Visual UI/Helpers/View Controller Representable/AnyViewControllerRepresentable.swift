//
//  AnyViewControllerRepresentable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct AnyViewControllerRepresentable: ViewControllerRepresentable {
    
    enum Destination {
        case offlineHelp
        case routeGuidance
        case manageDevices
    }
    
    // MARK: Properties
    
    let destination: Destination
    
    // MARK: `ViewControllerRepresentable`
    
    func makeViewController() -> UIViewController? {
        let sIdentifier: String
        let vIdentifier: String
        
        switch destination {
        case .offlineHelp:
            sIdentifier = "Help"
            vIdentifier = "OfflinePage"
        case .routeGuidance:
            sIdentifier = "RecreationalActivities"
            vIdentifier = "RouteDetailsView"
        case .manageDevices:
            sIdentifier = "Devices"
            vIdentifier = "manageDevices"
        }
        
        let storyboard = UIStoryboard(name: sIdentifier, bundle: Bundle.main)
        return storyboard.instantiateViewController(identifier: vIdentifier)
    }
    
}

extension AnyViewControllerRepresentable {
    
    // MARK: Static Initializers
    
    static let offlineHelp = AnyViewControllerRepresentable(destination: .offlineHelp)
    static let routeGuidance = AnyViewControllerRepresentable(destination: .routeGuidance)
    static let manageDevices = AnyViewControllerRepresentable(destination: .manageDevices)
    
}
