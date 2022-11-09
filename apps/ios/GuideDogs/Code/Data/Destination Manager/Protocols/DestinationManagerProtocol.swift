//
//  DestinationManagerProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

protocol DestinationManagerProtocol: AnyObject {
    
    // MARK: Properties
    
    var destinationKey: String? { get }
    
    var isDestinationSet: Bool { get }
    
    var destination: ReferenceEntity? { get }
    
    var isAudioEnabled: Bool { get }
    
    var isBeaconInBounds: Bool { get }
    
    var isCurrentBeaconAsyncFinishable: Bool { get }
    
    var beaconPlayerId: AudioPlayerIdentifier? { get }
    var proximityBeaconPlayerId: AudioPlayerIdentifier? { get }
    
    // MARK: Methods
    
    func isUserWithinGeofence(_ userLocation: CLLocation) -> Bool
    
    func isDestination(key: String) -> Bool
    
    func setDestination(referenceID: String, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws
    
    @discardableResult
    func setDestination(location: CLLocation, address: String?, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws -> String
    
    @discardableResult
    func setDestination(location: GenericLocation, address: String?, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws -> String
    
    @discardableResult
    func setDestination(entityKey: String, enableAudio: Bool, userLocation: CLLocation?, estimatedAddress: String?, logContext: String?) throws -> String
    
    @discardableResult
    func setDestination(location: CLLocation, behavior: String, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws -> String

    func clearDestination(logContext: String?) throws
    
    @discardableResult
    func toggleDestinationAudio(_ sendNotfication: Bool, automatic: Bool, forceMelody: Bool) -> Bool
    
    @discardableResult
    func updateDestinationLocation(_ newLocation: CLLocation, userLocation: CLLocation) -> Bool
}

// This extension adds the ability to not pass the `logContext` argument
extension DestinationManagerProtocol {
    func setDestination(referenceID: String, enableAudio: Bool, userLocation: CLLocation?) throws {
        try setDestination(referenceID: referenceID, enableAudio: enableAudio, userLocation: userLocation, logContext: nil)
    }
    
    @discardableResult
    func setDestination(location: CLLocation, address: String?, enableAudio: Bool, userLocation: CLLocation?) throws -> String {
        return try setDestination(location: location, address: address, enableAudio: enableAudio, userLocation: userLocation, logContext: nil)
    }
    
    @discardableResult
    func setDestination(entityKey: String, enableAudio: Bool, userLocation: CLLocation?, estimatedAddress: String?) throws -> String {
        return try setDestination(entityKey: entityKey, enableAudio: enableAudio, userLocation: userLocation, estimatedAddress: estimatedAddress, logContext: nil)
    }
    
    func clearDestination() throws {
        return try clearDestination(logContext: nil)
    }
    
    @discardableResult
    func toggleDestinationAudio(_ sendNotfication: Bool = true, automatic: Bool = true, forceMelody: Bool = false) -> Bool {
        return toggleDestinationAudio(sendNotfication, automatic: automatic, forceMelody: forceMelody)
    }
}
