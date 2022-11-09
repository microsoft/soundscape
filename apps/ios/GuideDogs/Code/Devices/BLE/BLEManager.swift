//
//  BLEManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreBluetooth

protocol BLEManagerScanDelegate: AnyObject {
    func onDeviceStateChanged(_ device: BLEDevice)
    func onDeviceNameChanged(_ device: BLEDevice, _ name: String)
    func onDevicesChanged(_ discovered: [BLEDevice])
}

extension Notification.Name {
    static let bluetoothDidUpdateState = Notification.Name("GDABluetoothDidUpdateState")
}

class BLEManager: NSObject {
    
    // MARK: Keys
    
    struct NotificationKeys {
        static let state = "GDAState"
    }
    
    /// Central Bluetooth manager
    private var centralManager: CBCentralManager!
    
    /// Dispatch queue used by the central manager for dispatching central role events
    private var queue = DispatchQueue(label: "com.company.appname.ble")
    
    /// Delegate object informed about device discovery events during a device scan. Set by a
    /// call to `startScan(for:delegate:)`.
    private weak var scanDelegate: BLEManagerScanDelegate?
    
    /// Type of the device that is being scanned for if a scan is occurring. The BLEManager will
    /// only scan for a single type of device at any given time.
    private var scanDeviceType: BLEDevice.Type?
    
    /// Devices discovered when scanning
    private(set) var discoveredDevices: [BLEDevice] = []
    
    /// Devices pending connection
    private(set) var pendingDevices: [BLEDevice] = []
    
    /// Devices that have successfully connected
    private(set) var connectedDevices: [BLEDevice] = []
    
    private var authorizationStatusQueryCompletion: ((Bool) -> Void)?
    
    /// Indicates if the central manager is in the `.poweredOn` state
    var isPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }
    
    /// Indicates if the central manager is currently scanning for devices
    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: queue, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }
    
    // MARK: Authorization
    
    func authorizationStatus(completion: @escaping (Bool) -> Void) {
        if centralManager.state == .unknown {
            // The completion will be called in `centralManagerDidUpdateState()`
            authorizationStatusQueryCompletion = completion
        } else {
            completion(centralManager.state != .unauthorized)
        }
    }
    
    // MARK: Connecting Devices
    
    /// Retrieves a known peripheral using it's identifier.
    ///
    /// - Parameter identifier: Peripheral identifier
    func retrievePeripheral(with identifier: UUID) -> CBPeripheral? {
        return centralManager.retrievePeripherals(withIdentifiers: [identifier]).first
    }
    
    /// Requests for the central manager to connect to the given bluetooth device.
    ///
    /// - Parameter device: Device to connect to
    func connect(_ device: BLEDevice) {
        pendingDevices.append(device)
        centralManager.connect(device.peripheral, options: nil)
    }
    
    /// Disconnects from any connected devices and cancels any pending connections.
    private func disconnectDevices() {
        for device in pendingDevices {
            cancelConnection(device, notify: false)
        }
        
        for device in connectedDevices {
            cancelConnection(device, notify: false)
        }
    }
    
    /// Cancels a pending or active connection to a peripheral
    ///
    /// - Parameter device: Device for the peripheral that is pending or actively connected
    /// - Parameter notify: Indicates if the scan delegate should be notified that the connection has been cancelled
    func cancelConnection(_ device: BLEDevice, notify: Bool = true) {
        // If the device is available, cancel any connection
        guard device.peripheral.state != .disconnected else {
            GDLogBLEError("Cannot disconnect from a device that is already disconnected!")
            return
        }
        
        device.onWillDisconnect(device.peripheral)
        centralManager.cancelPeripheralConnection(device.peripheral)
        
        if notify {
            scanDelegate?.onDeviceStateChanged(device)
        }
    }
    
    // MARK: Scanning for Devices
    
    /// Starts a device scan for the specified type of device. The BLEManager will only scan for
    /// a single type of device of a time in order to minimize the energy impact of the scan.
    ///
    /// - Parameter type: BLEDevice type
    /// - Parameter delegate: Scan delegate to notify about discovered devices
    func startScan(for type: BLEDevice.Type, delegate: BLEManagerScanDelegate) {
        guard !centralManager.isScanning else {
            return
        }
        
        GDLogBLEVerbose("Scanning for BLE devices...")
        
        scanDeviceType = type
        scanDelegate = delegate
        centralManager.scanForPeripherals(withServices: type.filterServiceIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
    }
    
    /// Stops the current BLE scan if one is occurring.
    func stopScan() {
        guard centralManager.isScanning else {
            return
        }
        
        GDLogBLEVerbose("Stopping BLE scan...")
        
        centralManager.stopScan()
        scanDelegate = nil
        scanDeviceType = nil
        discoveredDevices = []
    }
}

// MARK: CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let authorizationStatusQueryCompletion = authorizationStatusQueryCompletion, central.state != .unknown {
            DispatchQueue.main.async {
                authorizationStatusQueryCompletion(central.state != .unauthorized)
            }
            self.authorizationStatusQueryCompletion = nil
        }
        
        switch central.state {
        case .poweredOn:
            GDLogBLEVerbose("Central manager is powered on. Connecting known devices...")
        default:
            GDLogBLEVerbose("Central manager is not powered on. State: \(central.state.description). Disconnecting from all connected devices...")
            
            // If the BLE hardware isn't powered on, then we need to disconnect from all devices
            disconnectDevices()
        }
        
        NotificationCenter.default.post(name: Notification.Name.bluetoothDidUpdateState,
                                        object: self,
                                        userInfo: [BLEManager.NotificationKeys.state: central.state])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        GDLogBLEVerbose("Did discover to \(peripheral.identifier) (\(peripheral.name ?? "Unnamed Peripheral"))")
        
        // If we aren't scanning anymore, then ignore any further peripherals that are delivered
        guard centralManager.isScanning else {
            return
        }
        
        let id = peripheral.identifier
        
        // If this is just an update to a known device, then signal the update and be done
        if let device = discoveredDevices.first(where: { $0.peripheral.identifier == id }) {
            GDLogBLEVerbose("Discovered peripheral (update): \(peripheral.name ?? id.uuidString)")
            GDLogBLEVerbose("Advertisment data: \(advertisementData.debugDescription)")
            device.onWasDiscovered(peripheral, advertisementData: advertisementData)
            scanDelegate?.onDevicesChanged(discoveredDevices)
            return
        }
        
        GDLogBLEVerbose("Discovered peripheral: \(peripheral.name ?? id.uuidString)")
        GDLogBLEVerbose("Advertisment data: \(advertisementData.debugDescription)")
        
        guard let type = scanDeviceType else {
            return
        }
        
        let device = type.init(peripheral: peripheral, delegate: self)
        
        device.onWasDiscovered(peripheral, advertisementData: advertisementData)
        discoveredDevices.append(device)
        scanDelegate?.onDevicesChanged(discoveredDevices)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        GDLogBLEVerbose("Did connect to \(peripheral.identifier) (\(peripheral.name ?? "Unnamed Peripheral"))")
        
        guard let deviceIndex = pendingDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            GDLogBLEError("Unknown device type (services: \(peripheral.services?.debugDescription ?? "none")). Cancelling connection.")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        let device = pendingDevices.remove(at: deviceIndex)
        connectedDevices.append(device)
        device.onDidConnect(peripheral)
        scanDelegate?.onDeviceStateChanged(device)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        GDLogBLEError("Failed to connect to \(peripheral.name ?? "Unnamed peripheral") (\(peripheral.identifier))")
        
        guard let deviceIndex = pendingDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            GDLogBLEError("Unknown device type (services: \(peripheral.services?.debugDescription ?? "none")). Cancelling connection.")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        _ = pendingDevices.remove(at: deviceIndex)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        GDLogBLEVerbose("Disconnected from \(peripheral.name ?? "Unnamed peripheral") (\(peripheral.identifier))")
        
        guard let deviceIndex = connectedDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            GDLogBLEError("Unknown device type (services: \(peripheral.services?.debugDescription ?? "none")). Cancelling connection.")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        let device = connectedDevices.remove(at: deviceIndex)
        device.onDidDisconnect(peripheral)
        scanDelegate?.onDeviceStateChanged(device)
    }
}

// MARK: BLEDeviceDelegate

extension BLEManager: BLEDeviceDelegate {
    func onError(_ error: Error) {
        GDLogBLEError(error.localizedDescription)
    }
    
    func didConnect(_ device: BLEDevice) {
        scanDelegate?.onDeviceStateChanged(device)
    }

    func didUpdate(_ device: BLEDevice, name: String?) {
        guard let name = name else {
            return
        }
        
        scanDelegate?.onDeviceNameChanged(device, name)
    }
}

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "poweredOff"
        case .poweredOn: return "poweredOn"
        @unknown default: return "unknown - (WARNING) new enum value added"
        }
    }
}
