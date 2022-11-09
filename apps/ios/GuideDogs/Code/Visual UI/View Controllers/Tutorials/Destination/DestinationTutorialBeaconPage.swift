//
//  DestinationTutorialBeaconPage.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class DestinationTutorialBeaconPage: DestinationTutorialPage {
    
    // MARK: Content Strings
    
    let orientationDoesntMatterAirPods = GDLocalizedString("tutorial.beacons.text.OrientationAirPods")
    let orientationIsFlat = GDLocalizedString("tutorial.beacons.text.OrientationIsFlat")
    let orientationIsNotFlat = GDLocalizedString("tutorial.beacons.text.OrientationIsNotFlat")
    let orientationRepeat = GDLocalizedString("tutorial.beacons.text.OrientationRepeat")
    let holdingPhone = GDLocalizedString("tutorial.beacons.text.HoldingPhone")
    
    let beaconInitial = GDLocalizedString("tutorial.beacons.text.BeaconInitial")
    
    let beaconOutOfBounds = GDLocalizedString("tutorial.beacons.text.BeaconOutOfBounds")
    let beaconOutOfBoundsRotate = GDLocalizedString("tutorial.beacons.text.BeaconOutOfBoundsRotate")
    let beaconOutOfBoundsRotateHeadset = GDLocalizedString("tutorial.beacons.text.BeaconOutOfBoundsRotate.ar_headset")
    let beaconOutOfBoundsRepeat = GDLocalizedString("tutorial.beacons.text.BeaconOutOfBoundsRepeat")
    let beaconOutOfBoundsConfirmation = GDLocalizedString("tutorial.beacons.text.BeaconOutOfBoundsConfirmation")
    
    let beaconInBounds = GDLocalizedString("tutorial.beacons.text.BeaconInBounds")
    let beaconInBoundsRotate = GDLocalizedString("tutorial.beacons.text.BeaconInBoundsRotate")
    let beaconInBoundsRotateHeadset = GDLocalizedString("tutorial.beacons.text.BeaconInBoundsRotate.ar_headset")
    let beaconInBoundsRepeat = GDLocalizedString("tutorial.beacons.text.BeaconInBoundsRepeat")
    
    // MARK: Properties
    
    var phoneIsFlat = false
    var demoStarted = false
    var beaconStarted = false
    var beaconCompleted = false
    
    // MARK: Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let entity = entity else {
            return
        }
        
        let entityName = entity.name.isEmpty ? GDLocalizedString("poi.unknown") : entity.name
        pageTextLabel.text = GDLocalizedString("tutorial.beacon.poi_selected", entityName)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startDemo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pageFinished = true
        NotificationCenter.default.removeObserver(self, name: Notification.Name.phoneIsFlatChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.beaconInBoundsDidChange, object: nil)
    }
    
    func startDemo() {
        guard !demoStarted else {
            return
        }
        
        guard let entity = entity else {
            return
        }
        
        demoStarted = true
        
        let entityName = entity.name.isEmpty ? GDLocalizedString("poi.unknown") : entity.name

        play(delay: 1.0, text: GDLocalizedString("tutorial.beacon.poi_selected", entityName)) { [weak self] (finished) in
            guard finished else {
                return
            }
            
            guard let device = AppContext.shared.deviceManager.devices.first, device is UserHeadingProvider, device.isConnected else {
                self?.holdPhoneFlat()
                return
            }
            
            self?.startBeacon()
        }
    }
    
    func holdPhoneFlat() {
        guard !UIDeviceManager.isSimulator && !DeviceMotionManager.shared.isFlat else {
            play(text: orientationIsFlat) { [weak self] (finished) in
                guard finished else {
                    return
                }
                
                self?.startBeacon(true)
            }
            
            return
        }
        
        play(text: orientationIsNotFlat) { [weak self] (finished) in
            guard finished else {
                return
            }
            
            if DeviceMotionManager.shared.isFlat {
                self?.startBeacon()
            } else if let `self` = self {
                NotificationCenter.default.addObserver(self, selector: #selector(self.onPhoneIsFlatChanged), name: NSNotification.Name.phoneIsFlatChanged, object: nil)
                
                // Add in a backup timer here so that if the user doesn't do anything, we can prompt them again to do the gesture
                self.playRepeated(self.orientationRepeat, 10.0, { [weak self] () -> Bool in
                    return self?.beaconStarted ?? true
                })
            }
        }
    }
    
    @objc func onPhoneIsFlatChanged() {
        phoneIsFlat = DeviceMotionManager.shared.isFlat
        
        if phoneIsFlat && demoStarted {
            startBeacon()
        }
    }
    
    func startBeacon(_ alreadyFlat: Bool = false) {
        guard !beaconStarted else {
            return
        }
        
        beaconStarted = true
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.phoneIsFlatChanged, object: nil)
        
        let string: String
            
        if let device = AppContext.shared.deviceManager.devices.first, device is UserHeadingProvider, device.isConnected {
            switch device {
            case _ as HeadphoneMotionManagerWrapper:
                string = orientationDoesntMatterAirPods
                
            default:
                string = holdingPhone
            }
        } else if alreadyFlat {
            string = holdingPhone
        } else {
            string = GDLocalizedString("tutorial.beacons.text.HoldingPhone.great")
        }
        
        play(text: string) { [weak self] (finished) in
            guard finished, let `self` = self else {
                return
            }
            
            self.play(delay: 0.5, text: self.beaconInitial) { [weak self] (finished) in
                guard finished else {
                    return
                }
                
                self?.delegate?.pauseBackgroundTrack { [weak self] in
                    AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
                    
                    self?.searchForTing()
                }
            }
        }
    }
    
    @objc func checkBeacon(_ notification: Notification) {
        guard let isBeaconInBounds = notification.userInfo?[DestinationManager.Keys.isBeaconInBounds] as? Bool else {
            return
        }
        
        guard isBeaconInBounds else {
            return
        }
        
        beaconCompleted = true
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.beaconInBoundsDidChange, object: nil)
        
        completeOutOfBoundsRotate()
    }
    
    @objc func checkBeaconOff(_ notification: Notification) {
        guard let isBeaconInBounds = notification.userInfo?[DestinationManager.Keys.isBeaconInBounds] as? Bool else {
            return
        }
        
        guard !isBeaconInBounds else {
            return
        }
        
        beaconCompleted = true
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.beaconInBoundsDidChange, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.delegate?.pageComplete()
        }
    }
    
    func searchForTing() {
        guard !UIDeviceManager.isSimulator && !isBeaconInBounds() else {
            play(delay: 3.0, text: beaconInBounds) { [weak self] (finished) in
                guard finished, let `self` = self else {
                    return
                }
                
                let string: String
                
                if let device = AppContext.shared.deviceManager.devices.first, device is UserHeadingProvider, device.isConnected {
                    string = self.beaconInBoundsRotateHeadset
                } else {
                    string = self.beaconInBoundsRotate
                }
                    
                self.play(delay: 0.5, text: string) { [weak self] (finished) in
                    guard finished, let `self` = self else {
                        return
                    }
                    
                    if UIDeviceManager.isSimulator || !self.isBeaconInBounds() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            self?.delegate?.pageComplete()
                        }
                    } else {
                        NotificationCenter.default.addObserver(self, selector: #selector(self.checkBeaconOff), name: NSNotification.Name.beaconInBoundsDidChange, object: nil)
                        
                        // Add in a backup timer here so that if the user doesn't do anything, we can prompt them again to do the gesture
                        self.playRepeated(self.beaconInBoundsRepeat, 10.0, { [weak self] () -> Bool in
                            return self?.beaconCompleted ?? true
                        })
                    }
                }
            }
            
            return
        }
        
        play(delay: 3.0, text: beaconOutOfBounds) { [weak self] (finished) in
            guard finished, let `self` = self else {
                return
            }
            
            let string: String
            
            if let device = AppContext.shared.deviceManager.devices.first, device is UserHeadingProvider, device.isConnected {
                string = self.beaconOutOfBoundsRotateHeadset
            } else {
                string = self.beaconOutOfBoundsRotate
            }
            
            self.play(delay: 0.5, text: string) { [weak self] (finished) in
                guard finished, let `self` = self else {
                    return
                }
            
                if UIDeviceManager.isSimulator || self.isBeaconInBounds() {
                    self.completeOutOfBoundsRotate()
                } else {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.checkBeacon), name: NSNotification.Name.beaconInBoundsDidChange, object: nil)
                    
                    // Add in a backup timer here so that if the user doesn't do anything, we can prompt them again to do the gesture
                    self.playRepeated(self.beaconOutOfBoundsRepeat, 10.0, { [weak self] () -> Bool in
                        return self?.beaconCompleted ?? true
                    })
                }
            }
            
        }
    }
    
    private func completeOutOfBoundsRotate() {
        play(delay: 1.0, text: beaconOutOfBoundsConfirmation) { [weak self] (finished) in
            guard finished else {
                return
            }
            
            self?.delegate?.pageComplete()
        }
    }
    
    private func isBeaconInBounds() -> Bool {
        return AppContext.shared.spatialDataContext.destinationManager.isBeaconInBounds
    }
    
}
