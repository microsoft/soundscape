//
//  DynamicAudioEngineAssets.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// MARK: Original Beacons

enum ClassicBeacon: String, DynamicAudioEngineAsset {
    case beatOn = "Classic_OnAxis"
    case beatOff = "Classic_OffAxis"
    
    static var selector: AssetSelector? = ClassicBeacon.defaultSelector()
    static var beatsInPhrase: Int = 2
}

enum V2Beacon: String, DynamicAudioEngineAsset {
    case center = "Current_A+"
    case offset = "Current_A"
    case side   = "Current_B"
    case behind = "Current_Behind"
    
    static var selector: AssetSelector? = V2Beacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

// MARK: Exploratory Beacons

enum TactileBeacon: String, DynamicAudioEngineAsset {
    case center = "Tactile_OnAxis"
    case offset = "Tactile_OffAxis"
    case behind = "Tactile_Behind"
    
    static var selector: AssetSelector? = TactileBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum FlareBeacon: String, DynamicAudioEngineAsset {
    case center = "Flare_A+"
    case offset = "Flare_A"
    case side   = "Flare_B"
    case behind = "Flare_Behind"
    
    static var selector: AssetSelector? = FlareBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum ShimmerBeacon: String, DynamicAudioEngineAsset {
    case center = "Shimmer_A+"
    case offset = "Shimmer_A"
    case side   = "Shimmer_B"
    case behind = "Shimmer_Behind"
    
    static var selector: AssetSelector? = ShimmerBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum PingBeacon: String, DynamicAudioEngineAsset {
    case center = "Ping_A+"
    case offset = "Ping_A"
    case side   = "Ping_B"
    case behind = "Tactile_Behind"
    
    static var selector: AssetSelector? = PingBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum DropBeacon: String, DynamicAudioEngineAsset {
    case center = "Drop_A+"
    case offset = "Drop_A"
    case behind = "Drop_Behind"
    
    static var selector: AssetSelector? = DropBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum SignalBeacon: String, DynamicAudioEngineAsset {
    case center = "Signal_A+"
    case offset = "Signal_A"
    case behind = "Drop_Behind"
    
    static var selector: AssetSelector? = SignalBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum SignalSlowBeacon: String, DynamicAudioEngineAsset {
    case center = "Signal_Slow_A+"
    case offset = "Signal_Slow_A"
    case behind = "Signal_Slow_Behind"
    
    static var selector: AssetSelector? = SignalSlowBeacon.defaultSelector()
    static let beatsInPhrase: Int = 12
}

enum SignalVerySlowBeacon: String, DynamicAudioEngineAsset {
    case center = "Signal_Very_Slow_A+"
    case offset = "Signal_Very_Slow_A"
    case behind = "Signal_Very_Slow_Behind"
    
    static var selector: AssetSelector? = SignalVerySlowBeacon.defaultSelector()
    static let beatsInPhrase: Int = 18
}

enum MalletBeacon: String, DynamicAudioEngineAsset {
    case center = "Mallet_A+"
    case offset = "Mallet_A"
    case behind = "Mallet_Behind"
    
    static var selector: AssetSelector? = MalletBeacon.defaultSelector()
    static let beatsInPhrase: Int = 6
}

enum MalletSlowBeacon: String, DynamicAudioEngineAsset {
    case center = "Mallet_Slow_A+"
    case offset = "Mallet_Slow_A"
    case behind = "Mallet_Slow_Behind"
    
    static var selector: AssetSelector? = MalletSlowBeacon.defaultSelector()
    static let beatsInPhrase: Int = 12
}

enum MalletVerySlowBeacon: String, DynamicAudioEngineAsset {
    case center = "Mallet_Very_Slow_A+"
    case offset = "Mallet_Very_Slow_A"
    case behind = "Mallet_Very_Slow_Behind"
    
    static var selector: AssetSelector? = MalletVerySlowBeacon.defaultSelector()
    static let beatsInPhrase: Int = 18
}

// MARK: - Distance-Based Beacons

enum ProximityBeacon: String, DynamicAudioEngineAsset {
    case far = "Proximity_Far"
    case near = "Proximity_Close"
    
    static let beatsInPhrase: Int = 6
    
    static var selector: AssetSelector? = { input in
        if case .location(let user, let beacon) = input {
            guard let user = user else {
                return (.far, 0.0)
            }
            
            let distance = user.distance(from: beacon)
            
            if distance < 20.0 {
                return (.near, 1.0)
            } else if distance < 30.0 {
                return (.far, 1.0)
            } else {
                return (.far, 0.0)
            }
        }
        
        return nil
    }
    
}

// MARK: - Helper Assets

enum BeaconAccents: String, DynamicAudioEngineAsset {
    case start = "Route_Start"
    case end = "Route_End"
    
    static var selector: AssetSelector?
    static let beatsInPhrase: Int = 6
}

enum PreviewWandAsset: String, DynamicAudioEngineAsset {
    case noTarget = "2.4_roadFinder_loop_rev2_wFades"
    
    static var selector: AssetSelector?
    static var beatsInPhrase: Int = 1
}
