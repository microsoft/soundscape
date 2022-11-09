//
//  InteractiveBeaconViewModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import Combine

class InteractiveBeaconViewModel: ObservableObject {
    
    enum Orientation {
        case ahead
        case behind
        case other
    }
    
    // MARK: Properties
    
    @Published var isBeaconInBounds = false
    @Published var bearingToBeacon = 0.0
    @Published var beaconOrientation: Orientation = .other
    
    private let publisher: Heading
    private var heading: CLLocationDegrees?
    private let location: CLLocation?
    private var listeners: [AnyCancellable] = []
    
    // MARK: Initialization
    
    init() {
        publisher = AppContext.shared.geolocationManager.presentationHeading
        
        // Save initial values
        heading = publisher.value
        location = AppContext.shared.geolocationManager.location
        
        updateCurrentValues()
        
        publisher.onHeadingDidUpdate { [weak self] heading in
            guard let `self` = self else {
                return
            }
            
            self.heading = heading?.value
            
            self.updateCurrentValues()
        }
        
        listeners.append(NotificationCenter.default.publisher(for: .destinationChanged)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.updateCurrentValues()
        }))
    }
    
    deinit {
        // Remove handler
        publisher.onHeadingDidUpdate(nil)
        
        // Remove listeners
        listeners.cancelAndRemoveAll()
    }
    
    private func updateCurrentValues() {
        guard let location = location else {
            return
        }
        
        guard let heading = heading else {
            return
        }
        
        guard let bearingToLocation = AppContext.shared.spatialDataContext.destinationManager.destination?.bearingToClosestLocation(from: location) else {
            return
        }
        
        bearingToBeacon = heading.bearing(to: bearingToLocation)
        isBeaconInBounds = AppContext.shared.spatialDataContext.destinationManager.isBeaconInBounds
        
        if bearingToBeacon > 345.0 || bearingToBeacon < 15.0 {
            beaconOrientation = .ahead
        } else if bearingToBeacon > 165.0 && bearingToBeacon < 195.0 {
            beaconOrientation = .behind
        } else {
            beaconOrientation = .other
        }
    }
    
}
