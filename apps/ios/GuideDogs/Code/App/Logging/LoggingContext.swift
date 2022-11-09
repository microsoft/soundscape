//
//  LoggingContext.swift
//  Soundscape
//
//  Description:
//
// This class manages the application logs, including showing/hiding logs
// and determining which loggers to output to.

import Foundation
import CocoaLumberjackSwift

// MARK: Constants

struct BLELoggerUUIDs {
    static let BLELoggerServiceUUIDString = "C171E500-0000-0000-0000-5E7A1CE00000"
    static let BLELoggerCharacteristicUUIDString = "C171E500-0000-0000-0000-CAA6AC7E6157"
}

// MARK: Logger Types

enum Logger: Int {
    case console    = 1 // Xcode console
    case system     = 2 // Apple system
    case file       = 3 // File
    case bluetooth  = 4 // Bluetooth

    static var all: [Logger] {
        return [.console, .system, .file, .bluetooth]
    }
    
    static var simulator: [Logger] {
        return [.console, .file]
    }
    
    static var local: [Logger] {
        return [.console, .system, .file]
    }
    
    static func toRawValues(loggers: [Logger]) -> [Int] {
        var rawValues: [Int] = []
        for logger in loggers {
            rawValues.append(logger.rawValue)
        }
        return rawValues
    }

    static func fromRawValues(rawValues: [Int]) -> [Logger] {
        var loggers: [Logger] = []
        for rawValue in rawValues {
            if let logger = Logger(rawValue: rawValue) {
                loggers.append(logger)
            }
        }
        return loggers
    }
}

// MARK: Log Contexts

enum LogContext: Int {
    case `default`
    case network
    case audio
    case location
    case battery
    case action
    case spatialData
    case autoCallout
    case application
    case geocoder
    case settings
    case intCallout
    case motion
    case hardware
    case commandProcessor
    case eventProcessor
    case audioSession
    case ble
    case stateMachine
    case remoteManager
    case universalLink
    case push
    case cloud
    case preview
    case cmHeadphoneMotion
    case routeGuidance
    case urlResource
    case authoredContent
    
    var symbol: String {
        switch self {
        case .default: return "[---]"
        case .network: return "[NET]"
        case .audio: return "[AUD]"
        case .location: return "[LOC]"
        case .battery: return "[BAT]"
        case .action: return "[ACT]"
        case .spatialData: return "[SPT]"
        case .autoCallout: return "[CAL]"
        case .application: return "[APP]"
        case .geocoder: return "[GEO]"
        case .settings: return "[SET]"
        case .intCallout: return "[INT]"
        case .motion: return "[MOT]"
        case .hardware: return "[HDW]"
        case .commandProcessor: return "[CMD]"
        case .eventProcessor: return "[EVT]"
        case .audioSession: return "[AUS]"
        case .ble: return "[BLE]"
        case .stateMachine: return "[STM]"
        case .remoteManager: return "[RMT]"
        case .universalLink: return "[UNL]"
        case .push: return "[PSH]"
        case .cloud: return "[CLD]"
        case .preview: return "[PRE]"
        case .cmHeadphoneMotion: return "[CMH]"
        case .routeGuidance: return "[RTG]"
        case .urlResource: return "[URL]"
        case .authoredContent: return "[ATH]"
        }
    }
}

// MARK: Log Types

internal func GDLogVerbose(_ context: LogContext, _ message: String) {
    DDLogVerbose(message, context: context.rawValue)
}

internal func GDLogInfo(_ context: LogContext, _ message: String) {
    DDLogInfo(message, context: context.rawValue)
}

internal func GDLogWarn(_ context: LogContext, _ message: String) {
    DDLogWarn(message, context: context.rawValue)
}

internal func GDLogError(_ context: LogContext, _ message: String) {
    DDLogError(message, context: context.rawValue)
}

public func GDLogSpatialDataVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.spatialData.rawValue)
}

public func GDLogSpatialDataWarn(_ message: String) {
    DDLogWarn(message, context: LogContext.spatialData.rawValue)
}

public func GDLogSpatialDataError(_ message: String) {
    DDLogError(message, context: LogContext.spatialData.rawValue)
}

public func GDLogNetworkVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.network.rawValue)
}

public func GDLogNetworkWarn(_ message: String) {
    DDLogWarn(message, context: LogContext.network.rawValue)
}

public func GDLogNetworkError(_ message: String) {
    DDLogError(message, context: LogContext.network.rawValue)
}

public func GDLogAudioInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.audio.rawValue)
}

public func GDLogAudioVerbose(_ message: String) {
    DDLogInfo(message, context: LogContext.audio.rawValue)
}

public func GDLogAudioError(_ message: String) {
    DDLogError(message, context: LogContext.audio.rawValue)
}

public func GDLogBatteryInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.battery.rawValue)
}

public func GDLogActionInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.action.rawValue)
}

public func GDLogAppInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.application.rawValue)
}

public func GDLogAppVerbose(_ message: String) {
    DDLogInfo(message, context: LogContext.application.rawValue)
}

public func GDLogAppError(_ message: String) {
    DDLogError(message, context: LogContext.application.rawValue)
}

public func GDLogAutoCalloutInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.autoCallout.rawValue)
}

public func GDLogAutoCalloutError(_ message: String) {
    DDLogError(message, context: LogContext.autoCallout.rawValue)
}

public func GDLogAutoCalloutVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.autoCallout.rawValue)
}

public func GDLogLocationInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.location.rawValue)
}

public func GDLogLocationVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.location.rawValue)
}

public func GDLogLocationError(_ message: String) {
    DDLogError(message, context: LogContext.location.rawValue)
}

public func GDLogGeocoderInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.geocoder.rawValue)
}

public func GDLogSettingsInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.settings.rawValue)
}

public func GDLogIntersectionInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.intCallout.rawValue)
}

public func GDLogIntersectionWarn(_ message: String) {
    DDLogWarn(message, context: LogContext.intCallout.rawValue)
}

public func GDLogIntersectionError(_ message: String) {
    DDLogError(message, context: LogContext.intCallout.rawValue)
}

public func GDLogMotionVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.motion.rawValue)
}

public func GDLogCommandProcInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.commandProcessor.rawValue)
}

public func GDLogCommandProcError(_ message: String) {
    DDLogError(message, context: LogContext.commandProcessor.rawValue)
}

public func GDLogCommandProcVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.commandProcessor.rawValue)
}

public func GDLogEventProcessorInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.eventProcessor.rawValue)
}

public func GDLogEventProcessorError(_ message: String) {
    DDLogError(message, context: LogContext.eventProcessor.rawValue)
}

public func GDLogEventProcessorVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.eventProcessor.rawValue)
}

public func GDLogAudioSessionInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.audioSession.rawValue)
}

public func GDLogAudioSessionWarn(_ message: String) {
    DDLogWarn(message, context: LogContext.audioSession.rawValue)
}

public func GDLogBLEInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.ble.rawValue)
}

public func GDLogBLEVerbose(_ message: String) {
    DDLogInfo(message, context: LogContext.ble.rawValue)
}

public func GDLogBLEError(_ message: String) {
    DDLogError(message, context: LogContext.ble.rawValue)
}

public func GDLogStateMachineVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.stateMachine.rawValue)
}

public func GDLogRemoteManagerVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.remoteManager.rawValue)
}

public func GDLogRemoteManagerWarn(_ message: String) {
    DDLogWarn(message, context: LogContext.remoteManager.rawValue)
}

public func GDLogRemoteManagerError(_ message: String) {
    DDLogError(message, context: LogContext.remoteManager.rawValue)
}

public func GDLogUniversalLinkError(_ message: String) {
    DDLogError(message, context: LogContext.universalLink.rawValue)
}

public func GDLogPushInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.push.rawValue)
}

public func GDLogPushError(_ message: String) {
    DDLogError(message, context: LogContext.push.rawValue)
}

public func GDLogCloudInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.cloud.rawValue)
}

public func GDLogPreviewInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.preview.rawValue)
}

public func GDLogPreviewError(_ message: String) {
    DDLogError(message, context: LogContext.preview.rawValue)
}

public func GDLogHeadphoneMotionInfo(_ message: String) {
    DDLogInfo(message, context: LogContext.cmHeadphoneMotion.rawValue)
}

public func GDLogHeadphoneMotionError(_ message: String) {
    DDLogError(message, context: LogContext.cmHeadphoneMotion.rawValue)
}

public func GDLogHeadphoneMotionVerbose(_ message: String) {
    guard FeatureFlag.isEnabled(.developerTools) else {
        return
    }
    
    guard DebugSettingsContext.shared.isHeadphoneMotionVerboseLoggingEnabled else {
        return
    }
    
    DDLogVerbose(message, context: LogContext.cmHeadphoneMotion.rawValue)
}

public func GDLogURLResourceError(_ message: String) {
    DDLogError(message, context: LogContext.urlResource.rawValue)
}

public func GDLogURLResourceVerbose(_ message: String) {
    DDLogVerbose(message, context: LogContext.urlResource.rawValue)
}

// MARK: -

class LoggingContext {
    
    // MARK: Properties
    
    static let shared = LoggingContext()
    
    var currentLoggers: [Logger] {
        get {
            return DebugSettingsContext.shared.loggers
        }
        set(newLoggers) {
            DebugSettingsContext.shared.loggers = newLoggers
        }
    }
    
    var fileLogger: DDFileLogger = {
        let fileLogger: DDFileLogger = DDFileLogger()
        fileLogger.logFormatter = LogFormatter()
        fileLogger.rollingFrequency = 0
        fileLogger.maximumFileSize = 0
        fileLogger.logFileManager.maximumNumberOfLogFiles = 14
        fileLogger.doNotReuseLogFiles = true
        return fileLogger
    }()
    
    // MARK: Actions
    
    func startAllLoggers() {
        start(with: Logger.all)
    }
    
    func start() {
        if UIDeviceManager.isSimulator {
            start(with: Logger.simulator)
        } else {
            start(with: DebugSettingsContext.shared.loggers)
        }
    }
    
    func start(with loggers: [Logger]) {
        stop()
        
        currentLoggers = loggers
        
        guard !loggers.isEmpty else {
            return
        }
        
        if loggers.contains(.console), let ttyLogger = DDTTYLogger.sharedInstance {
            ttyLogger.logFormatter = LogFormatter()
            DDLog.add(ttyLogger)
        }

        if loggers.contains(.system) {
            DDOSLogger.sharedInstance.logFormatter = LogFormatter()
            DDLog.add(DDOSLogger.sharedInstance)
        }
        
        if loggers.contains(.file) {
            DDLog.add(fileLogger)
        }
        
        if loggers.contains(.bluetooth) {
            let logFormatter = LogFormatter()
            logFormatter.showFileAndLineNumber = false // Bluetooth has a limit on data we can send, so make it short
            BLELogger.sharedInstance.logFormatter = logFormatter
            
            BLELogger.sharedInstance.setup(characteristicUUID: BLELoggerUUIDs.BLELoggerCharacteristicUUIDString,
                                           serviceUUID: BLELoggerUUIDs.BLELoggerServiceUUIDString)
            DDLog.add(BLELogger.sharedInstance)
        }
    }
    
    func stop() {
        DDLog.removeAllLoggers()
    }
}
