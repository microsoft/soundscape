//
//  DestinationTutorialPage.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import AVFoundation

protocol DestinationTutorialPageDelegate: AnyObject {
    func getEntityKey() -> String?
    func pauseBackgroundTrack(_ completion: (() -> Void)?)
    func resumeBackgroundTrack()
    func pageComplete()
    func tutorialComplete()
}

class DestinationTutorialPage: BaseTutorialViewController {
    
    // MARK: Properties
    
    weak var delegate: DestinationTutorialPageDelegate?
    
    var entity: ReferenceEntity? {
        guard let key = delegate?.getEntityKey() else {
            return nil
        }
        
        return SpatialDataCache.referenceEntityByKey(key)
    }
    
    // MARK: BaseTutorialViewController Overrides
    
    override internal func play(delay: TimeInterval = 0.0, text: String, _ completion: ((Bool) -> Void)? = nil) {
        var textToPlay = text
        
        if text.contains("@!destination!!") {
            textToPlay = text.replacingOccurrences(of: "@!destination!!", with: entity?.name ?? GDLocalizedString("tutorial.beacon.your_destination"))
        }
        
        super.play(delay: delay, text: textToPlay, completion)
    }
    
}
