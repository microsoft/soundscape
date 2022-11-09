//
//  BLEDevice.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreBluetooth

protocol BLEDeviceDelegate: AnyObject {
    func onError(_ error: Error)
    func didConnect(_ device: BLEDevice)
    func didUpdate(_ device: BLEDevice, name: String?)
}

enum BLEDeviceState {
    case unknown
    case disconnected
    case initializing
    case ready
    case disconnecting
}

enum BLEDeviceType {
    case headset
    case remote
}

protocol BLEDevice: CBPeripheralDelegate {
    /// Optional service UUIDs used for discovering devices of this type
    static var filterServiceIDs: [CBUUID] { get }
    
    /// A list of known services the device supports
    static var services: [BLEDeviceService.Type] { get }
    
    /// A delegate for responding to device events
    var delegate: BLEDeviceDelegate? { get }

    /// Indicates what type of device this object is
    var deviceType: BLEDeviceType { get }
    
    /// CBPeripheral object owned by this BLEDevice
    var peripheral: CBPeripheral { get }
    
    /// State of this BLEDevice. When a BLEDevice object is first created, it should
    /// be in the .unknown state. After it is discovered by the BLEManager, it should
    /// move into the .disconnected state. When it is connected or connecting to the
    /// BLEManager but not yet ready for the app to use (e.g. in the process of discovering
    /// services/characteristics or authenticating) it should be in the .initializing
    /// state. When the device is ready to be used by the app, it should be in the
    /// .ready state. If the device disconnects, it will move to the .disconnecting state
    /// and then the .disconnected state.
    var state: BLEDeviceState { get }

    /// Initializer for the BLEDevice
    ///
    /// - Parameters:
    ///   - peripheral: The underlying CBPeripheral object
    ///   - delegate: Delegate for responding to device events
    init(peripheral: CBPeripheral, delegate: BLEDeviceDelegate?)
    
    /// Called when this device is discovered by the BLEManager (or when the advertisement
    /// data updates).
    ///
    /// - Parameter peripheral: peripheral object for this device
    func onWasDiscovered(_ peripheral: CBPeripheral, advertisementData: [String: Any])

    /// Called when this device is connected by the BLEManager
    ///
    /// - Parameter peripheral: peripheral object for this device
    func onDidConnect(_ peripheral: CBPeripheral)
    
    /// Called when this device is being disconnected
    ///
    /// - Parameter peripheral: peripheral object for this device
    func onWillDisconnect(_ peripheral: CBPeripheral)

    /// Called when this device is disconnected from the BLEManager
    ///
    /// - Parameter peripheral: peripheral object for this device
    func onDidDisconnect(_ peripheral: CBPeripheral)

    /// Called when all known services and charactertistics have been discovered
    func onSetupComplete()

    /// Called when the device is ready to be used. Characteristics can be read/subscribed to here.
    func onConnectionComplete()
}

extension BLEDevice {
    static var serviceUUIDs: [CBUUID] {
        return services.map({ $0.uuid })
    }

    static func serviceType(for uuid: CBUUID) -> BLEDeviceService.Type? {
        return services.first(where: { $0.uuid == uuid })
    }
}

protocol BLEDeviceService {
    static var uuid: CBUUID { get }
    
    static var characteristicUUIDs: [CBUUID] { get }
}

protocol BatteryLevelAnnounceable: AnyObject {
    var batteryLevel: Int? { get set }
    var lowBatteryAnnounced: Bool { get set }
}

extension BatteryLevelAnnounceable where Self: BLEDevice {
    func updateBatteryLevel(_ level: Int, name: String, logPrefix: String) {
        batteryLevel = level
        
        GDLogBLEVerbose("\(logPrefix): battery level \(level)%")
        
        guard level < 20 && !lowBatteryAnnounced else {
            return
        }
        
        lowBatteryAnnounced = true
        
        let announcement = GDLocalizedString("callouts.hardware.low_battery", name, String(level))
        AppContext.process(GenericAnnouncementEvent(announcement))
    }
}

protocol StringCBUUIDEnum: RawRepresentable, CaseIterable {
    var uuid: CBUUID { get }
}

extension StringCBUUIDEnum where RawValue == String {
    var uuid: CBUUID {
        return CBUUID(string: rawValue)
    }
}

struct BLEAssignedNumbers {
    static let deviceInfo = CBUUID(string: "180A")
}

struct BLEDeviceInfoService: BLEDeviceService {
    static var uuid: CBUUID = CBUUID(string: "180A")
    
    static var characteristicUUIDs: [CBUUID] {
        return Characteristic.allCases.map({ $0.uuid })
    }
    
    enum Characteristic: String, StringCBUUIDEnum {
        case manufacturerName = "2A29"
        case modelNumber = "2A24"
        case serialNumber = "2A25"
        case hardwareRevision = "2A27"
        case firmwareRevision = "2A26"
        case softwareRevision = "2A28"
        case systemID = "2A23"
        case regulatoryInfo = "2A2A"
        case pnpID = "2A50"
    }
    
    static func process(_ type: Characteristic, _ characteristic: CBCharacteristic) -> String? {
        guard let value = characteristic.value else {
            return nil
        }
        
        switch type {
        case .softwareRevision, .firmwareRevision, .hardwareRevision, .manufacturerName, .serialNumber:
            return String(data: value, encoding: .utf8)

        case .pnpID:
            return nil

        default:
            return nil
        }
    }
}

struct BLEBatteryLevelService: BLEDeviceService {
    static var uuid: CBUUID = CBUUID(string: "180F")
    
    static var characteristicUUIDs: [CBUUID] {
        return Characteristic.allCases.map({ $0.uuid })
    }
    
    enum Characteristic: String, StringCBUUIDEnum {
        case batteryLevel = "2A19"
    }
    
    /// Processes the battery level characteristic and returns the battery level.
    ///
    /// - Parameter characteristic: A `CBCharacteristic` object for the battery level characteristic
    /// - Returns: The battery level. Nil if the characteristic cannot be parsed
    static func process(_ characteristic: CBCharacteristic) -> Int? {
        guard let level = characteristic.value?.to(type: UInt8.self) else {
            return nil
        }
        
        return Int(level)
    }
}
