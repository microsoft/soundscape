//
//  BeaconOption+Strings.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension BeaconOption {
    
    var localizedName: String {
        switch self {
        case .original: return GDLocalizedString("beacon.styles.original")
        case .current: return GDLocalizedString("beacon.styles.current")
        case .flare: return GDLocalizedString("beacon.styles.flare")
        case .shimmer: return GDLocalizedString("beacon.styles.shimmer")
        case .tacticle: return GDLocalizedString("beacon.styles.tactile")
        case .ping: return GDLocalizedString("beacon.styles.ping")
        case .drop: return GDLocalizedString("beacon.styles.drop")
        case .signal: return GDLocalizedString("beacon.styles.signal")
        case .signalSlow: return GDLocalizedString("beacon.styles.signal.slow")
        case .signalVerySlow: return GDLocalizedString("beacon.styles.signal.very_slow")
        case .mallet: return GDLocalizedString("beacon.styles.mallet")
        case .malletSlow: return GDLocalizedString("beacon.styles.mallet.slow")
        case .malletVerySlow: return GDLocalizedString("beacon.styles.mallet.very_slow")
        case .wand: return GDLocalizedString("beacon.styles.haptic.wand")
        case .pulse: return GDLocalizedString("beacon.styles.haptic.pulse")
        }
    }
    
}
