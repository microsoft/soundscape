//
//  LogFormatter.swift
//  Soundscape
//
//  Description:
//
//  This class provides a log formatter with the following template:
//  [date] [flag] [function] [line]: [message]
//  Example:
//  2016-12-02 18:39:33:967 Ⓥ open()(40): file opened
//

import UIKit
import CocoaLumberjack

class LogFormatter: NSObject {
    
    // MARK: Properties

    static var dateFormatter: DateFormatter = LogFormatter.defaultDateFormatter()

    var showFileAndLineNumber = false
    
    fileprivate var logFlagDisplayStringVerbose = "Ⓥ"
    fileprivate var logFlagDisplayStringDebug   = "Ⓓ"
    fileprivate var logFlagDisplayStringInfo    = "Ⓘ"
    fileprivate var logFlagDisplayStringWarn    = "Ⓦ"
    fileprivate var logFlagDisplayStringError   = "Ⓔ"
    
}

// MARK: - DDLogFormatter

extension LogFormatter: DDLogFormatter {
    
    func format(message logMessage: DDLogMessage) -> String? {
        let message: String = logMessage.message
        
        let logFlagDisplayString: String!
        
        switch logMessage.flag {
        case DDLogFlag.error:
            logFlagDisplayString = logFlagDisplayStringError
        case DDLogFlag.warning:
            logFlagDisplayString = logFlagDisplayStringWarn
        case DDLogFlag.info:
            logFlagDisplayString = logFlagDisplayStringInfo
        case DDLogFlag.debug:
            logFlagDisplayString = logFlagDisplayStringDebug
        case DDLogFlag.verbose:
            logFlagDisplayString = logFlagDisplayStringVerbose
        default:
            logFlagDisplayString = ""
        }
        
        let date = LogFormatter.dateFormatter.string(from: logMessage.timestamp)
        let function: String = logMessage.function ?? ""

        let formattedString = showFileAndLineNumber ?
            "\(date) \(LogContext(rawValue: logMessage.context)?.symbol ?? "[---]") \(logFlagDisplayString!) \(function)(\(logMessage.line)) \(message)" :
            "\(date) \(LogContext(rawValue: logMessage.context)?.symbol ?? "[---]") \(message)"
        
        return formattedString
    }
}

// MARK: - Helpers

extension LogFormatter {
    
    class func defaultDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return dateFormatter
    }

    func setLogFlagDisplayStrings(verbose: String, debug: String, info: String, warn: String, error: String) {
        logFlagDisplayStringVerbose = verbose
        logFlagDisplayStringDebug = debug
        logFlagDisplayStringInfo = info
        logFlagDisplayStringWarn = warn
        logFlagDisplayStringError = error
    }
}
