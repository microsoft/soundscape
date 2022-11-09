//
//  GPXExtensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import iOS_GPX_Framework
import CoreMotion.CMMotionActivity

public typealias GPXActivity = String

public struct GPXLocation {
    var location: CLLocation
    var deviceHeading: Double?
    var activity: GPXActivity?
}

extension GPXBounds {
    convenience init?(with locations: [GPXLocation]) {
        guard let firstLocation = locations.first?.location else {
            return nil
        }
        
        var minLatitude = firstLocation.coordinate.latitude
        var maxLatitude = firstLocation.coordinate.latitude
        var minLongitude = firstLocation.coordinate.longitude
        var maxLongitude = firstLocation.coordinate.longitude

        for gpxLocation in locations {
            let location = gpxLocation.location
            
            if location.coordinate.latitude < minLatitude {
                minLatitude = location.coordinate.latitude
            }
            if location.coordinate.latitude > maxLatitude {
                maxLatitude = location.coordinate.latitude
            }
            if location.coordinate.latitude < minLongitude {
                minLongitude = location.coordinate.longitude
            }
            if location.coordinate.latitude > maxLongitude {
                maxLongitude = location.coordinate.longitude
            }
        }
        
        self.init(minLatitude: minLatitude,
                  minLongitude: minLongitude,
                  maxLatitude: maxLatitude,
                  maxLongitude: maxLongitude)
    }
}

extension GPXRoot {
    
    class func defaultRoot() -> GPXRoot {
        let creator = "\(AppContext.appDisplayName) \(AppContext.appVersion) (\(AppContext.appBuild))"
        let root = GPXRoot(creator: creator)
        
        let metadata = GPXMetadata()
        metadata.time = Date()
        metadata.desc = "Created on \(UIDevice.current.model) (\(UIDevice.current.systemName) \(UIDevice.current.systemVersion))"
        
        let author = GPXAuthor()
        author.name = UIDevice.current.name
        metadata.author = author
        
        root.metadata = metadata
        
        return root
    }
    
    class func createGPX(withTrackLocations trackLocations: [GPXLocation]) -> GPXRoot {
        let root = GPXRoot.defaultRoot()
        root.metadata?.bounds = GPXBounds(with: trackLocations)
        
        let trackSegment = GPXTrackSegment()
        for gpxLocation in trackLocations {
            trackSegment.addTrackpoint(GPXTrackPoint(with: gpxLocation))
        }
        
        let track = GPXTrack()
        track.addTracksegment(trackSegment)
        
        root.addTrack(track)
        
        return root
    }
}

extension GPXWaypoint {

    /// This can be used to check if a timestamp of a `CLLocation` created with a waypoint is compared to nil.
    /// Date is `Date(timeIntervalSince1970: 0)`.
    class func noDateIdentifier() -> Date {
        return Date(timeIntervalSince1970: 0)
    }
    
    var hasSoundscapeExtension: Bool {
        return extensions?.soundscapeExtensions != nil
    }
    
    convenience init(with gpxLocation: GPXLocation) {
        self.init()
        
        let location = gpxLocation.location
        
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        elevation = location.altitude
        time = location.timestamp
        
        let garminExtension = GPXTrackPointExtensions()
        garminExtension.speed = NSNumber(value: location.speed)
        garminExtension.course = NSNumber(value: location.course)
        
        let soundscapeExtension = GPXSoundscapeExtensions()
        soundscapeExtension.horizontalAccuracy = NSNumber(value: location.horizontalAccuracy)
        soundscapeExtension.verticalAccuracy = NSNumber(value: location.verticalAccuracy)
        
        if let heading = gpxLocation.deviceHeading {
            soundscapeExtension.deviceHeading = NSNumber(value: heading)
        }
        
        if let activity = gpxLocation.activity, activity != ActivityType.unknown.rawValue {
            soundscapeExtension.activity = activity
        }
        
        let extensions = GPXExtensions()
        extensions.garminExtensions = garminExtension
        extensions.soundscapeExtensions = soundscapeExtension

        self.extensions = extensions
    }

    /// Note: if a waypoint's timestamp is nil (when the GPX file does not contain time values),
    /// we use `noDateIdentifier` to symbolize nil, because `CLLocation` cannot contain nil timestamps.
    func gpxLocation() -> GPXLocation {
        var speed: CLLocationSpeed = -1
        var course: CLLocationDirection = -1
        
        var horizontalAccuracy: CLLocationAccuracy = -1
        var verticalAccuracy: CLLocationAccuracy = -1

        var trueHeading: CLLocationDirection = -1
        var magneticHeading: CLLocationDirection = -1
        var headingAccuracy: CLLocationDirection = -1
        
        var deviceHeading: Double?

        var activity: GPXActivity?

        // Backwards compatibility: previuosly Soundscape used the dilution values for accuracy
        horizontalAccuracy = horizontalDilution
        verticalAccuracy = verticalDilution

        if let extensions = extensions {
            // Backwards compatibility: previuosly Soundscape used to store speed and course directly in the extensions class
            speed = extensions.speed
            course = extensions.course
            
            if let garminExtensions = extensions.garminExtensions {
                if let garminSpeed = garminExtensions.speed, let speedNum = CLLocationSpeed(exactly: garminSpeed) {
                    speed = speedNum
                }
                
                if let garminCourse = garminExtensions.course, let courseNum = CLLocationDirection(exactly: garminCourse) {
                    course = courseNum
                }
            }
            
            if let soundscapeExtensions = extensions.soundscapeExtensions {
                if let hAcc = soundscapeExtensions.horizontalAccuracy, let hAccNum = CLLocationAccuracy(exactly: hAcc) {
                    horizontalAccuracy = hAccNum
                }
                
                if let vAcc = soundscapeExtensions.verticalAccuracy, let vAccNum = CLLocationAccuracy(exactly: vAcc) {
                    verticalAccuracy = vAccNum
                }
                
                if let sTrueHeading = soundscapeExtensions.trueHeading, let sTrueHeadingNum = CLLocationDirection(exactly: sTrueHeading) {
                    trueHeading = sTrueHeadingNum
                }
                
                if let sMagneticHeading = soundscapeExtensions.magneticHeading, let sMagneticHeadingNum = CLLocationDirection(exactly: sMagneticHeading) {
                    magneticHeading = sMagneticHeadingNum
                }
                
                if let sHeadingAccuracy = soundscapeExtensions.headingAccuracy, let sHeadingAccuracyNum = CLLocationDirection(exactly: sHeadingAccuracy) {
                    headingAccuracy = sHeadingAccuracyNum
                }
                
                if let sDeviceHeading = soundscapeExtensions.deviceHeading, let sDeviceHeadingNum = CLLocationDirection(exactly: sDeviceHeading) {
                    deviceHeading = sDeviceHeadingNum
                }
                
                // Previous versions of the GPX tracker
                // and simulator used `trueHeading` and `magneticHeading`
                // rather than `deviceHeading`
                // If necessary, translate `trueHeading` and `magneticHeading`
                // to `deviceHeading`
                if deviceHeading == nil {
                    if trueHeading >= 0.0 {
                        // Use `trueHeading` if it is valid
                        // `trueHeading` is valid if its value is >= 0.0
                        deviceHeading = trueHeading
                    } else if headingAccuracy >= 0.0 {
                        // Use `magneticHeading` if it is valid
                        // `magneticHeading` is valid if `headingAccuracy` is >= 0.0
                        deviceHeading = magneticHeading
                    }
                }
                
                activity = soundscapeExtensions.activity
            }
        }
        
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                  altitude: elevation,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: course,
                                  speed: speed,
                                  timestamp: time ?? GPXWaypoint.noDateIdentifier())
        
        return GPXLocation(location: location, deviceHeading: deviceHeading, activity: activity)
    }
    
}

extension Array where Element == CLLocationCoordinate2D {
    func toGPXRoute() -> GPXRoute {
        let routePoints = self.compactMap { GPXRoutePoint.routepoint(withLatitude: CGFloat($0.latitude),
                                                                     longitude: CGFloat($0.longitude)) }
        let route = GPXRoute()
        route.addRoutepoints(routePoints)
        
        return route
    }
}
