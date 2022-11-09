//
//  SoundscapeBehavior.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class SoundscapeBehavior: BehaviorBase {
    
    init(geo: GeolocationManagerProtocol,
         data: SpatialDataProtocol,
         reverseGeocoder: ReverseGeocoder,
         deviceManager: DeviceManagerProtocol,
         motionActivity: MotionActivityProtocol,
         deviceMotion: DeviceMotionProvider) {
        
        super.init()
        
        let auto = AutoCalloutGenerator(settings: SettingsContext.shared, data: data, geocoder: reverseGeocoder, geo: geo)
        let beacon = BeaconCalloutGenerator(data: data, geo: geo, settings: SettingsContext.shared)
        let explore = ExplorationGenerator(data: data,
                                           geocoder: reverseGeocoder,
                                           geo: geo,
                                           motionActivity: motionActivity,
                                           deviceMotion: deviceMotion)

        manualGenerators.append(SystemGenerator(geo: geo, device: deviceManager))
        manualGenerators.append(HeadsetTestGenerator())
        manualGenerators.append(explore)
        manualGenerators.append(beacon)
        manualGenerators.append(auto)
        
        // Note that the order in which generators are added matters. Generators that are
        // added first, get the first opportunity to consume events that have `distribution`
        // set to `EventDistribution.consumed`.
        autoGenerators.append(IntersectionGenerator(self, geoManager: geo, data: data, geocoder: reverseGeocoder))
        autoGenerators.append(ARHeadsetGenerator())
        autoGenerators.append(explore)
        autoGenerators.append(beacon)
        autoGenerators.append(auto)
    }
    
}
