//
//  DynamicAudioEngineAsset.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

enum AssetSelectorInput {
    case heading(CLLocationDirection?, CLLocationDirection)
    case location(CLLocation?, CLLocation)
}

/// `DynamicAudioEngineAsset`s are distinct from standard `AudioEngineAsset`s in several
/// ways. They represent a set of audio components that together represent a single
/// continuous experience during which one of the components is always playing (i.e. think
/// audio beacon). Implementations of `DynamicAudioEngineAsset` must provide a "selector"
/// block that is responsible for choosing which asset should be playing at any given time.
/// The selector block can return `nil` allowing for the dynamic asset design to include
/// silence. Each audio component should be the same length (i.e. have the same number
/// of frames) and the implementation should indicate how many beats there are in the musical
/// phrase the components compose - this allows for intelligently switching between assets on
/// the beat.
protocol DynamicAudioEngineAsset: AudioEngineAsset, CaseIterable, Hashable {
    typealias Volume = Float
    
    /// A block which takes a user heading and a bearing to a POI and returns the case for the
    /// asset that should be playing and the volume the player should be playing at.
    typealias AssetSelector = (AssetSelectorInput) -> (asset: AllCases.Element, volume: Volume)?
    
    static var selector: AssetSelector? { get }
    
    static var beatsInPhrase: Int { get }
}

extension DynamicAudioEngineAsset {
    static var description: String {
        return String(describing: self)
    }
    
    /// Returns an appropriate default asset selector based on the number of asset in
    /// the dynamic audio engine asset (defined for asset counts of 2, 3, and 4).
    ///
    /// - Returns: An asset selector
    static func defaultSelector() -> AssetSelector? {
        switch allCases.count {
        case 2: return standardTwoRegionSelector()
        case 3: return standardThreeRegionSelector()
        case 4: return standardFourRegionSelector()
        default: return nil
        }
    }
    
    /// A default beacon asset selector for three regions (On Axis, Off Axis)
    ///
    /// The two regions are defined as follows:
    ///  * On Axis: Central 45 degrees, `(angle >= 337.5 || angle <= 22.5)`
    ///  * Off Axis: Remaining window, `(angle <  337.5 && angle >  22.5)`
    ///
    /// - Returns: An asset selector
    static func standardTwoRegionSelector() -> AssetSelector? {
        guard allCases.count == 2 else {
            return nil
        }
        
        let assets = Array(allCases)
        
        return { input in
            if case .heading(let userHeading, let poiBearing) = input {
                guard let userHeading = userHeading else {
                    return (assets[1], 1.0)
                }
                
                let angle = userHeading.add(degrees: -poiBearing)
                
                // 45 degree window for the V1SensoryBeatOn sound
                if angle >= 337.5 || angle <= 22.5 {
                    return (assets[0], 1.0)
                } else {
                    return (assets[1], 1.0)
                }
            }
            
            return nil
        }
    }
    
    /// A default beacon asset selector for three regions (A+, A, Behind)
    ///
    /// The three regions are defined as follows:
    ///  * A+: Central 30 degrees, `(angle >= 345 || angle <= 15)`
    ///  * A: 110 degree windows to either side of A+, `(angle >= 235 && angle <= 345) || (angle >= 15 && angle <= 125)`
    ///  * Behind: Remaining window, `(angle >  125 && angle <  235)`
    ///
    /// - Returns: An asset selector
    static func standardThreeRegionSelector() -> AssetSelector? {
        guard allCases.count == 3 else {
            return nil
        }
        
        let assets = Array(allCases)
        
        return { input in
            if case .heading(let userHeading, let poiBearing) = input {
                guard let userHeading = userHeading else {
                    return (assets[2], 1.0)
                }
                
                let angle = userHeading.add(degrees: -poiBearing)
                
                if angle >= 345 || angle <= 15 {
                    return (assets[0], 1.0)
                } else if (angle >= 235 && angle <= 345) || (angle >= 15 && angle <= 125) {
                    return (assets[1], 1.0)
                } else {
                    return (assets[2], 1.0)
                }
            }
            
            return nil
        }
    }
    
    /// A default beacon asset selector for three regions (A+, A, B, Behind)
    ///
    /// The two regions are defined as follows:
    ///  * A+: Central 30 degrees, `(angle >= 345 || angle <= 15)`
    ///  * A: 40 degree windows, `(angle >= 305 && angle <= 345) || (angle >= 15 && angle <= 55)`
    ///  * B: 70 degree windows, `(angle >= 235 && angle <= 305) || (angle >= 55 && angle <= 125)`
    ///  * Behind: Remaining window, `angle >  125 && angle <  235`
    ///
    /// - Returns: An asset selector
    static func standardFourRegionSelector() -> AssetSelector? {
        guard allCases.count == 4 else {
            return nil
        }
        
        let assets = Array(allCases)
        
        return { input in
            if case .heading(let userHeading, let poiBearing) = input {
                guard let userHeading = userHeading else {
                    return (assets[3], 1.0)
                }
                
                let angle = userHeading.add(degrees: -poiBearing)
                
                if angle >= 345 || angle <= 15 {
                    return (assets[0], 1.0)
                } else if (angle >= 305 && angle <= 345) || (angle >= 15 && angle <= 55) {
                    return (assets[1], 1.0)
                } else if (angle >= 235 && angle <= 305) || (angle >= 55 && angle <= 125) {
                    return (assets[2], 1.0)
                } else {
                    return (assets[3], 1.0)
                }
            }
            
            return nil
        }
    }
}
