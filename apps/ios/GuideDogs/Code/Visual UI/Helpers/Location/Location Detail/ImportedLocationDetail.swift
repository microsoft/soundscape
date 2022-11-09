//
//  ImportedLocationDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct ImportedLocationDetail {
    
    // MARK: Properties
    
    let nickname: String?
    let annotation: String?
    // Waypoint Detail
    let departureCallout: String?
    let arrivalCallout: String?
    let images: [ActivityWaypointImage]?
    let audio: [ActivityWaypointAudioClip]?
    
    // MARK: Initialization
    
    init(nickname: String?, annotation: String?, departure: String? = nil, arrival: String? = nil, images: [ActivityWaypointImage]? = nil, audio: [ActivityWaypointAudioClip]? = nil) {
        if let nickname = nickname, nickname.isEmpty == false {
            self.nickname = nickname
        } else {
            // If the string is empty, save `nil`
            self.nickname = nil
        }
        
        if let annotation = annotation, annotation.isEmpty == false {
            self.annotation = annotation
        } else {
            // If the string is empty, save `nil`
            self.annotation = nil
        }
        
        if let departure = departure, departure.isEmpty == false {
            self.departureCallout = departure
        } else {
            // If the string is empty, save `nil`
            self.departureCallout = nil
        }
        
        if let arrival = arrival, arrival.isEmpty == false {
            self.arrivalCallout = arrival
        } else {
            // If the string is empty, save `nil`
            self.arrivalCallout = nil
        }
        
        self.images = images
        self.audio = audio
    }
    
}
