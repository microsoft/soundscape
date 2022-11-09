//
//  DestinationTutorialMutePage.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class DestinationTutorialMutePage: DestinationTutorialPage {
    // MARK: Content Strings
    
    let mute = GDLocalizedString("tutorial.beacons.text.Mute")
    let muteRepeat = GDLocalizedString("tutorial.beacons.text.MuteRepeat")
    let wrapUp = GDLocalizedString("tutorial.beacons.text.WrapUp")
    
    // MARK: Properties
    
    var magicTapOccurred = false
    
    // MARK: Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pageTextLabel.text = mute
        
        NotificationCenter.default.addObserver(self, selector: #selector(onMagicTapOccurred), name: Notification.Name.magicTapOccurred, object: nil)
        
        play(text: mute) { [weak self] (finished) in
            guard finished else {
                return
            }
            
            self?.delegate?.pauseBackgroundTrack(nil)
            
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
                
            NotificationCenter.default.post(name: NSNotification.Name.enableMagicTap, object: self)
            
            guard !UIDeviceManager.isSimulator else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    AppContext.shared.eventProcessor.hush()
                    self?.onMagicTapOccurred()
                }
                return
            }
            
            if let `self` = self {
                // Add in a backup timer here so that if the user doesn't do anything, we can prompt them again to do the gesture
                self.playRepeated(self.muteRepeat, 10.0, { [weak self] () -> Bool in
                    return self?.magicTapOccurred ?? true
                })
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pageFinished = true
    }
    
    @objc func onMagicTapOccurred() {
        guard !magicTapOccurred else {
            return
        }
        
        magicTapOccurred = true
        
        NotificationCenter.default.post(name: NSNotification.Name.disableMagicTap, object: self)
        
        delegate?.resumeBackgroundTrack()
        
        play(text: wrapUp) { [weak self] (_) in
            guard let `self` = self else {
                return
            }

            NotificationCenter.default.removeObserver(self, name: Notification.Name.magicTapOccurred, object: nil)
            self.delegate?.tutorialComplete()
        }
    }
}
