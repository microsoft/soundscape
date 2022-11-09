//
//  DynamicSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import CoreLocation

protocol DynamicSound: SoundBase {
    associatedtype AssetType: DynamicAudioEngineAsset
    
    var commonFormat: AVAudioFormat { get }
    
    var introAsset: BeaconAccents? { get }
    
    var outroAsset: BeaconAccents? { get }
    
    func asset(for userHeading: CLLocationDirection?, userLocation: CLLocation) -> (asset: AssetType, volume: AssetType.Volume)?
    
    func asset(userLocation: CLLocation) -> (asset: AssetType, volume: AssetType.Volume)?
    
    func buffer(for asset: AssetType?) -> AVAudioPCMBuffer
    
    func buffer(for melody: BeaconAccents) -> AVAudioPCMBuffer
}
