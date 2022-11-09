//
//  GPXTracker.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import iOS_GPX_Framework
import CoreMotion.CMMotionActivity

class GPXTracker {
    
    // MARK: Properties
    
    private(set) var isTracking = false

    private(set) var rawLocations: [GPXLocation] = []
    private(set) var smoothLocations: [GPXLocation] = []
    
    private let queue = DispatchQueue(label: "com.company.appname.gpxtracker")
    
    // MARK: Tracking state

    func startTracking() {
        reset()
        
        isTracking = true
    }
    
    func stopTracking() {
        isTracking = false
        
        save()
    }
    
    func reset() {
        isTracking = false
        
        rawLocations.removeAll()
        smoothLocations.removeAll()
    }
    
    func track(location: GPXLocation, raw: Bool = true) {
        if raw {
            rawLocations.append(location)
        } else {
            smoothLocations.append(location)
        }
    }
    
    // MARK: Saving

    private func save() {
        queue.async {
            self.save(locations: self.rawLocations, filenameSuffix: "raw")
            self.save(locations: self.smoothLocations, filenameSuffix: "smooth")
            
            DispatchQueue.main.async {
                self.reset()
            }
        }
    }
    
    private func save(locations: [GPXLocation], filenameSuffix suffix: String = "") {
        guard locations.count > 0 else {
            GDLogLocationInfo("No locations tracked. Not saving GPX file.")
            return
        }
        
        // GPX filename will be the first location's timestamp
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyy-MM-dd HH-mm-ss"
        
        // Save the GPX file
        let filename = "\(formatter.string(from: locations.first?.location.timestamp ?? Date()))-\(suffix)"
        let root = GPXRoot.createGPX(withTrackLocations: locations)
        if !GPXFileManager.create(content: root.gpx(), filename: filename) {
            GDLogLocationError("Error saving GPX file!")
        }
    }
    
}
