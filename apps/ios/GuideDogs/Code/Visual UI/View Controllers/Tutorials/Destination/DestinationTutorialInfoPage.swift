//
//  DestinationTutorialInfoPage.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreLocation

class DestinationTutorialInfoPage: DestinationTutorialPage {
    
    // MARK: Content Strings
    
    let mobilitySkills = GDLocalizedString("tutorial.beacons.text.MobilitySkills")
    let automaticCallout = GDLocalizedString("tutorial.beacons.text.AutomaticCallout")
    let homeScreen = GDLocalizedString("tutorial.beacons.text.HomeScreen")
    
    // MARK: Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pageTextLabel.text = mobilitySkills
        
        AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
        
        self.delegate?.resumeBackgroundTrack()
        
        play(delay: 1.0, text: mobilitySkills) { [weak self] (finished) in
            guard finished, let `self` = self else {
                return
            }
            
            self.play(delay: 1.0, text: self.automaticCallout) { [weak self] (finished) in
                guard finished, let `self` = self else {
                    return
                }
                
                self.delegate?.pauseBackgroundTrack({ [weak self] in
                    self?.playCallout()
                })
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pageFinished = true
    }
    
    private func playCallout() {
        guard let entity = self.entity, let location = AppContext.shared.geolocationManager.location else {
            // Return if destination could not be retrieved
            return
        }
        
        let distance = entity.distanceToClosestLocation(from: location)
        let loc = CLLocation(latitude: entity.latitude, longitude: entity.longitude)
        let callout = LanguageFormatter.string(from: distance,
                                               accuracy: location.horizontalAccuracy,
                                               name: GDLocalizedString("beacon.generic_name"))
        
        AppContext.process(GenericAnnouncementEvent(callout, glyph: .poiSense, location: loc) { [weak self] (finished) in
            guard finished else {
                return
            }
            
            self?.delegate?.resumeBackgroundTrack()
            self?.calloutCompleted()
        })
    }
    
    private func calloutCompleted() {
        play(text: homeScreen, { [weak self] (finished) in
            guard finished else {
                return
            }
            
            self?.delegate?.pageComplete()
        })
    }
    
}
