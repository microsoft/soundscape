//
//  GeolocationManagerProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol GeolocationManagerProtocol: AnyObject {
    var isActive: Bool { get }
    var coreLocationServicesEnabled: Bool { get }
    var coreLocationAuthorizationStatus: CoreLocationAuthorizationStatus { get }
    
    var updateDelegate: GeolocationManagerUpdateDelegate? { get set }
    var location: CLLocation? { get }
    var collectionHeading: Heading { get }
    var presentationHeading: Heading { get }
    
    func heading(orderedBy types: [HeadingType]) -> Heading
    // `GeolocationManager` Life Cycle
    func start()
    func stop()
    func snooze()
    
    // MARK: Adding/Removing Providers
    
    func add(_ provider: LocationProvider)
    func remove(_ provider: LocationProvider)
    func add(_ provider: CourseProvider)
    func remove(_ provider: CourseProvider)
    func add(_ provider: UserHeadingProvider)
    func remove(_ provider: UserHeadingProvider)
}
