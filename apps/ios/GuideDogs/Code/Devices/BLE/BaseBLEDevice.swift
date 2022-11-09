//
//  BaseBLEDevice.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
import CoreBluetooth

class BaseBLEDevice: NSObject, BLEDevice {
    class var filterServiceIDs: [CBUUID] {
        // Get the service UUIDs from the child object implementation if no filter IDs were provided by the child implementation
        let myType = self as BLEDevice.Type
        return myType.serviceUUIDs
    }

    class var services: [BLEDeviceService.Type] {
        fatalError("Classes extending BaseBLEDevice must implement `services`")
    }

    weak var delegate: BLEDeviceDelegate?

    var deviceType: BLEDeviceType

    private(set) var peripheral: CBPeripheral {
        didSet {
            peripheral.delegate = self
        }
    }
    
    private(set) var advertisementData: [String: Any]?

    private(set) var logName: String

    private(set) var state: BLEDeviceState = .unknown

    private var queue: DispatchQueue = DispatchQueue(label: "com.company.appname.bledevice")
    private var charDiscoveryGroup: DispatchGroup = DispatchGroup()

    private(set) var services: [CBUUID: CBService] = [:]
    private(set) var characteristics: [CBUUID: CBCharacteristic] = [:]

    init(peripheral: CBPeripheral, type deviceType: BLEDeviceType, delegate: BLEDeviceDelegate?) {
        self.peripheral = peripheral
        self.delegate = delegate
        self.deviceType = deviceType
        self.logName = String(describing: type(of: self) as BLEDevice.Type)

        super.init()

        self.peripheral.delegate = self
    }

    /// This initializer should be overriden to specify the corrent device type.
    ///
    /// - Parameters:
    ///   - peripheral: A CBPeripheral device
    ///   - delegate: Delegate for responding to device events
    required convenience init(peripheral: CBPeripheral, delegate: BLEDeviceDelegate?) {
        fatalError("Classes that extend BaseBLEDevice must implement the required initializer and delegate to super.init()")
    }

    func onWasDiscovered(_ peripheral: CBPeripheral, advertisementData: [String: Any]) {
        // Always save the peripheral in `onWasDiscovered(_:)` to support reconnecting...
        self.peripheral = peripheral
        self.advertisementData = advertisementData

        if state == .unknown {
            state = .disconnected
        }
    }

    func onDidConnect(_ peripheral: CBPeripheral) {
        // Always save the peripheral in `onDidConnect(_:)` to support reconnecting...
        self.peripheral = peripheral

        state = .initializing

        // Get the service UUIDs from the child object implementation and kick off discovery
        let myType = type(of: self) as BLEDevice.Type
        peripheral.discoverServices(myType.serviceUUIDs)
    }

    func initializationComplete() {
        state = .ready

        delegate?.didConnect(self)
    }

    func onWillDisconnect(_ peripheral: CBPeripheral) {
        // Always save the peripheral in `onWillDisconnect(_:)` to support reconnecting...
        self.peripheral = peripheral

        state = .disconnecting
    }

    func onDidDisconnect(_ peripheral: CBPeripheral) {
        // Always save the peripheral in `onDidDisconnect(_:)` to support reconnecting...
        self.peripheral = peripheral

        state = .disconnected
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        delegate?.didUpdate(self, name: peripheral.name)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            delegate?.onError(error)
            return
        }

        // Make sure services were discovered
        guard let services = peripheral.services else {
            GDLogBLEError("\(logName): No services discovered!")
            return
        }

        GDLogBLEVerbose("\(logName): Discovered services.")

        for service in services {
            // Make sure this is a known service
            guard let serviceType = (type(of: self) as BLEDevice.Type).serviceType(for: service.uuid) else {
                continue
            }

            // Discover the characteristics
            charDiscoveryGroup.enter()
            peripheral.discoverCharacteristics(serviceType.characteristicUUIDs, for: service)
        }

        // After all of the characteristics for the known services have been discovered, kick off the pairing process by reading the GAIA MTU characteristic
        charDiscoveryGroup.notify(queue: queue) { [weak self] in
            guard let `self` = self else {
                return
            }

            self.onSetupComplete()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let serviceType = (type(of: self) as BLEDevice.Type).serviceType(for: service.uuid) else {
            return
        }
        
        defer {
            // Signal that we have the characteristics we were waiting for
            charDiscoveryGroup.leave()
        }
        
        if let error = error {
            delegate?.onError(error)
            return
        }

        guard let characteristics = service.characteristics else {
            GDLogBLEError("\(logName): No characteristics discovered for \(String(describing: serviceType.self))!")
            return
        }

        GDLogBLEInfo("\(logName): Discovered characteristics for \(String(describing: serviceType.self))")

        // Remember the service and its characteristics
        self.services[service.uuid] = service
        for characteristic in characteristics {
            self.characteristics[characteristic.uuid] = characteristic
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

    }

    func onSetupComplete() {
        onConnectionComplete()
    }

    func onConnectionComplete() {
        initializationComplete()
    }
}
