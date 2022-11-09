//
//  BLELogger.swift
//
//  Description:
//
// This class provides a custom CocoaLumberjack logger that sends logs wirelessly via Bluetooth.
// In order to intercept the logs, there is a helper project called *BLE Logger Client*.
// Running it will show logs from a nearby Guide Dogs app.
//

import UIKit
import CocoaLumberjackSwift
import CoreBluetooth

class BLELogger: DDAbstractLogger {
    
    // MARK: Properties
    
    static let sharedInstance = BLELogger()

    fileprivate var BLELoggerServiceCBUUID: CBUUID!
    fileprivate var BLELoggerCharacteristicCBUUID: CBUUID!
    
    fileprivate var logMessages: [DDLogMessage] = []
    fileprivate var sendDataIndex: Int = 0
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate var logCharacteristic: CBMutableCharacteristic!
    fileprivate var logService: CBMutableService!
    
    /// We use `internalLogFormatter` to solve the threading issue:
    /// https://github.com/CocoaLumberjack/CocoaLumberjack/issues/643
    fileprivate var internalLogFormatter: DDLogFormatter!
    override internal var logFormatter: DDLogFormatter! {
        get {
            return super.logFormatter
        }
        set {
            super.logFormatter = newValue
            internalLogFormatter = newValue
        }
    }

    // MARK: - Lifecycle
    
    deinit {
        stopAdvertising()
    }
    
    @objc func setup(characteristicUUID: String, serviceUUID: String) {
        BLELoggerCharacteristicCBUUID = CBUUID.init(string: characteristicUUID)
        BLELoggerServiceCBUUID = CBUUID.init(string: serviceUUID)

        logCharacteristic = CBMutableCharacteristic(type: BLELoggerCharacteristicCBUUID,
                                                    properties: [.notify],
                                                    value: nil,
                                                    permissions: .readable)
        
        logService = CBMutableService(type: BLELoggerServiceCBUUID, primary: true)
        logService.characteristics = [logCharacteristic]
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue(label: "com.company.appname.ble-logger"))
    }
    
    fileprivate func sendData() {
        guard logMessages.count > 0 else {
            return
        }
        
        let logMessage = logMessages.first!
        let transmissionFormat = BLELogger.transmittedDataFormat(logMessage: logMessage)
        guard let transmissionData = transmissionFormat.data(using: .utf8) else {
            return
        }
        
        // Send the log message to the subscribed centrals
        let didSendValue = peripheralManager.updateValue(transmissionData,
                                                         for: logCharacteristic,
                                                         onSubscribedCentrals: nil)
        
        guard didSendValue else {
            // The underlying transmit queue is full
            // If it didn't work, drop out and wait for the callback in
            // peripheralManagerIsReadyToUpdateSubscribers
            return
        }
        
        logMessages.remove(at: 0)
        sendData()
    }
}

// MARK: - Advertising

extension BLELogger {
    public func startAdvertising() {
        guard !peripheralManager.isAdvertising else {
            return
        }
        
        let advertisementData = [
            CBAdvertisementDataLocalNameKey: loggerName,
            CBAdvertisementDataServiceUUIDsKey: [logService.uuid]
            ] as [String: Any]
        peripheralManager.startAdvertising(advertisementData)
    }
    
    public func stopAdvertising() {
        guard peripheralManager.isAdvertising else {
            return
        }
        
        peripheralManager.stopAdvertising()
    }
}

// MARK: - DDAbstractLogger

extension BLELogger {
    
    override func log(message logMessage: DDLogMessage) {
        // Add to the log messsages queue
        logMessages.append(logMessage)
        
        if peripheralManager.isAdvertising {
            sendData()
        }
    }
    
    override func didAdd() {
        startAdvertising()
    }
    
    override func willRemove() {
        stopAdvertising()
    }
    
    override var loggerName: DDLoggerName {
        return DDLoggerName("com.company.appname.blelogger")
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLELogger: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print(#function)
        
        var statusMessage = ""
        
        switch peripheral.state {
        case .poweredOn:
            statusMessage = "Bluetooth Status: Powered On"
        case .poweredOff:
            statusMessage = "Bluetooth Status: Powered Off"
        case .resetting:
            statusMessage = "Bluetooth Status: Resetting"
        case .unauthorized:
            statusMessage = "Bluetooth Status: Unauthorized"
        case .unsupported:
            statusMessage = "Bluetooth Status: Unsupported"
        default:
            statusMessage = "Bluetooth Status: Unknown"
        }
        
        print(statusMessage)
        
        guard peripheralManager.state == .poweredOn else {
            return
        }
        peripheralManager.removeAllServices()
        peripheralManager.add(logService)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("\(#function) error: \(error != nil ? error!.localizedDescription : "")")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("\(#function) service: \(service.uuid.uuidString) error: \(error != nil ? error!.localizedDescription : "")")
        
        if let error = error {
            print(error)
        } else {
            startAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("\(#function) characteristic: \(characteristic.uuid.uuidString)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("\(#function) characteristic: \(characteristic.uuid.uuidString)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("\(#function) request characteristic: \(request.characteristic.uuid.uuidString)")
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print(#function)
        
        sendData()
    }
}

// MARK: - Transmitted Data Format

extension BLELogger {
    
    private static let delimiter = "~"
    
    /// Formats the `DDLogMessage` object as a string with the following format:
    /// date~context~flag~message
    /// Because BLE has a limit on a transmitted data packet, we don't send function names and other information to conserve space
    class func transmittedDataFormat(logMessage: DDLogMessage) -> String {
        return "\(logMessage.timestamp.timeIntervalSince1970)\(delimiter)\(logMessage.context)\(delimiter)\(logMessage.flag.rawValue)\(delimiter)\(logMessage.message)"
    }
    
    /// Transforms the formated string to a `DDLogMessage` object
    class func transmittedDataFormat(logString: String) -> DDLogMessage {
        let components: [String] = logString.components(separatedBy: delimiter)
        
        var timestamp: Date?
        var context: Int?
        var flag: DDLogFlag?
        var message: String?
    
        for (index, value) in components.enumerated() {
            switch index {
            case 0: timestamp = Date.init(timeIntervalSince1970: Double.init(value) ?? 0.0)
            case 1: context = Int.init(value)
            case 2: flag = DDLogFlag.init(rawValue: UInt.init(value) ?? DDLogFlag.verbose.rawValue)
            case 3: message = value
            default: break
            }
        }
        
        return DDLogMessage.init(message: message ?? "",
                                 level: dynamicLogLevel,
                                 flag: flag ?? DDLogFlag.verbose,
                                 context: context ?? 0,
                                 file: "",
                                 function: nil,
                                 line: 0,
                                 tag: nil,
                                 options: DDLogMessageOptions(rawValue: 0),
                                 timestamp: timestamp ?? Date())
    }
}
