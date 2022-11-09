//
//  AVAudioSession+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation.AVFAudio

extension AVAudioSession.RouteChangeReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .newDeviceAvailable: return "new device available"
        case .oldDeviceUnavailable: return "old device unavailable"
        case .categoryChange: return "category change"
        case .override: return "override"
        case .wakeFromSleep: return "wake from sleep"
        case .noSuitableRouteForCategory: return "no suitable route for category"
        case .routeConfigurationChange: return "route configuration change"
        @unknown default: return "unknown - (WARNING) new enum value added"
        }
    }
}

extension AVAudioSession.InterruptionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .began: return "began"
        case .ended: return "ended"
        @unknown default: return "unknown - (WARNING) new enum value added"
        }
    }
}

extension AVAudioSession.SilenceSecondaryAudioHintType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .begin: return "begin"
        case .end: return "end"
        @unknown default: return "unknown - (WARNING) new enum value added"
        }
    }
}

extension AVAudioSession.ErrorCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "none"
        case .mediaServicesFailed: return "mediaServicesFailed"
        case .isBusy: return "isBusy"
        case .incompatibleCategory: return "incompatibleCategory"
        case .cannotInterruptOthers: return "cannotInterruptOthers"
        case .missingEntitlement: return "missingEntitlement"
        case .siriIsRecording: return "siriIsRecording"
        case .cannotStartPlaying: return "cannotStartPlaying"
        case .cannotStartRecording: return "cannotStartRecording"
        case .badParam: return "badParam"
        case .insufficientPriority: return "insufficientPriority"
        case .resourceNotAvailable: return "resourceNotAvailable"
        case .unspecified: return "unspecified"
        case .expiredSession: return "expiredSession"
        case .sessionNotActive: return "sessionNotActive"
        @unknown default: return "unknown - (WARNING) new enum value added"
        }
    }
}
