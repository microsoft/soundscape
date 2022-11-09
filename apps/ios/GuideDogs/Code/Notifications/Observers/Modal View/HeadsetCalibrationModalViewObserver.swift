//
//  HeadsetCalibrationModalViewObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class HeadsetCalibrationModalViewObserver: PersistentNotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    private var isCalibrationRequired = false
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCalibrationRequired), name: Notification.Name.ARHeadsetCalibrationDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCalibrationDone), name: Notification.Name.ARHeadsetCalibrationDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCalibrationDone), name: Notification.Name.ARHeadsetCalibrationCancelled, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onCalibrationRequired() {
        self.isCalibrationRequired = true
        
        // Notify delegate
        delegate?.stateDidChange(self)
    }
    
    @objc
    private func onCalibrationDone() {
        self.isCalibrationRequired = false
        
        // Notify delegate
        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationManager`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard isCalibrationRequired else {
            return nil
        }
        
        guard (viewController is DevicesViewController) == false else {
            return nil
        }
        
        guard let viewController = UIStoryboard(name: "Devices", bundle: nil).instantiateViewController(withIdentifier: "manageDevices") as? DevicesViewController else {
            // Failed to instantiate view controller
            return nil
        }
        
        viewController.launchedAutomatically = true
        
        return viewController
    }
    
}
