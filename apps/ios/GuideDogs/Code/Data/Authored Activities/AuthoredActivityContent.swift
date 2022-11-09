//
//  AuthoredActivityContent.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import iOS_GPX_Framework

// MARK: - Data Models

struct ActivityWaypointImage {
    /// Network URL for the image
    let url: URL
    
    /// Alt text describing the image
    let altText: String?
}

struct ActivityWaypointAudioClip {
    /// Network URL for the audio clip
    let url: URL
    
    /// Description of the audio clip that can be displayed to users
    let description: String?
}

struct ActivityWaypoint {
    /// Location of the waypoint (GPX: wptType:lat/lon)
    let coordinate: CLLocationCoordinate2D
    
    /// Name or title for the geolocation represented by this waypoint (GPX: wptType:name)
    let name: String?
    
    /// Annotation for the geolocation represented by this waypoint (GPX: wptType:desc)
    let description: String?
    
    /// Text that should be called out when a beacon is first set on this waypoint
    let departureCallout: String?
    
    /// Text that should be called out when the user arrives at this callout
    let arrivalCallout: String?
    
    /// Link to a highlight images for the waypoint (GPX: wptType:link)
    let images: [ActivityWaypointImage]
    
    /// Link to audio clips associated with the waypoint (GPX: wptType:link)
    let audioClips: [ActivityWaypointAudioClip]
    
    /// Initializer for waypoints with default values for optional properties.
    ///
    /// - Parameters:
    ///   - coordinate: Location of the waypoint
    ///   - name: Name of the waypoint
    ///   - description: Description of the waypoint displayed to users
    ///   - departureCallout: Callout that is announced when the user first departs for the waypoint
    ///   - arrivalCallout: Callout that is announced when the user arrives at the waypoint
    ///   - images: Images associated with the waypoint
    ///   - audioClips: Audio clips associated with the waypoint
    init(coordinate: CLLocationCoordinate2D, name: String? = nil, description: String? = nil, departureCallout: String? = nil, arrivalCallout: String? = nil, images: [ActivityWaypointImage] = [], audioClips: [ActivityWaypointAudioClip] = []) {
        self.coordinate = coordinate
        self.name = name
        self.description = description
        self.departureCallout = departureCallout
        self.arrivalCallout = arrivalCallout
        self.images = images
        self.audioClips = audioClips
    }
}

class ActivityPOI {
    let id = UUID()
    
    /// Location of the waypoint (GPX: wptType:lat/lon)
    let coordinate: CLLocationCoordinate2D
    
    /// Name or title for the geolocation represented by this waypoint (GPX: wptType:name)
    let name: String
    
    /// Annotation for the geolocation represented by this waypoint (GPX: wptType:desc)
    let description: String?
    
    init(coordinate: CLLocationCoordinate2D, name: String, description: String?) {
        self.coordinate = coordinate
        self.name = name
        self.description = description
    }
}

enum AuthoredActivityType: String {
    case orienteering
    case guidedTour
    
    static func parse(_ label: String) -> AuthoredActivityType? {
        switch label.lowercased() {
        case "scavengerhunt":
            // This case exists to handle the v1 version of links before we moved to the term "orienteering"
            return .orienteering
            
        case AuthoredActivityType.orienteering.rawValue:
            return .orienteering
            
        case AuthoredActivityType.guidedTour.rawValue.lowercased():
            return .guidedTour
            
        default: return nil
        }
    }
}

/// Model object containing all the data for an adaptive sports event
struct AuthoredActivityContent {
    
    /// String identifier of this shared content. Used for downloading, saving, and loading content.
    var id: String
    
    /// The behavior type of this activity
    var type: AuthoredActivityType
    
    /// Name of the experience (GPX: metadata:name)
    var name: String
    
    /// Name of the person or organization that authored this content (GPX: metadata:author)
    let creator: String
    
    /// Shared content files are authored in specfic locales. To support content translation,
    /// shared content files must specify the locale of their content. (GPX: metadata:extensions:gpxsc:meta:locale)
    let locale: Locale
    
    /// A date interval describing the time span this content is valid for (e.g. a start
    /// and end date for an event). (GPX: metadata:extensions:gpxsc:meta:availability)
    let availability: DateInterval
    
    /// A flag indicating whether or not this event expires. If `true` users will not be able start the event after
    /// its availability period expires.
    let expires: Bool
    
    /// Link to a highlight image for the experience
    let image: URL?
    
    /// Description of the adaptive sports event (GPX: metadata:desc)
    let desc: String
    
    /// Points of interest waypoints included in this shared content (GPX: based on the presence of the wptType:extensions:gpxsc:poi extension)
    let waypoints: [ActivityWaypoint]
    
    /// POIs that are called out when the event is active
    let pois: [ActivityPOI]
    
    var isExpired: Bool {
        guard expires else {
            return false
        }
        
        return !availability.contains(Date())
    }
}

// MARK: - Parsing GPX Event Data

fileprivate extension GPXWaypoint {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension AuthoredActivityContent {
    var hasSavedState: Bool {
        return AuthoredActivityLoader.shared.hasState(id)
    }
    
    /// Parses a custom GPX file with the data for an adaptive sports event.
    ///
    /// - Parameter url: URL for downloading the GPX data
    /// - Throws: SharedContentError if the file cannot be parsed (or required data is missing)
    /// - Returns: An AdaptiveSportsEvent struct
    static func parse(gpx: GPXRoot) -> AuthoredActivityContent? {
        guard let metadata = gpx.metadata else {
            return nil
        }
        
        guard let ext = metadata.extensions?.soundscapeSCExtensions, let actType = AuthoredActivityType.parse(ext.behavior) else {
            return nil
        }
        
        guard let name = metadata.name, !name.isEmpty else {
            return nil
        }
        
        guard let creator = metadata.author.name, !creator.isEmpty else {
            return nil
        }
        
        guard let description = metadata.desc, !description.isEmpty else {
            return nil
        }
        
        var imageURL: URL?
        if let image = metadata.link, image.mimetype.hasPrefix("image") {
            imageURL = URL(string: image.href)
        }
        
        // Parse the waypoints and POIs based on the file version
        switch ext.version ?? "1" {
        case "1":
            let wpts: [ActivityWaypoint] = waypoints(from: gpx.waypoints)
            
            // For waypoints in this experience, require names, descriptions, and street addresses
            guard !wpts.isEmpty, !wpts.contains(where: { $0.name == nil }) else {
                return nil
            }
            
            return AuthoredActivityContent(id: ext.identifier,
                                           type: actType,
                                           name: name,
                                           creator: creator,
                                           locale: ext.locale,
                                           availability: ext.availability,
                                           expires: ext.expires,
                                           image: imageURL,
                                           desc: description,
                                           waypoints: wpts,
                                           pois: [])
            
        case "2":
            guard let route = gpx.routes.first, route.routepoints.count > 0 else {
                return nil
            }
            
            let wpts: [ActivityWaypoint] = waypoints(from: route.routepoints)
            
            // For waypoints in this experience, require names, descriptions, and street addresses
            guard !wpts.isEmpty, !wpts.contains(where: { $0.name == nil }) else {
                return nil
            }
            
            let pois = gpx.waypoints.map { ActivityPOI(coordinate: $0.coordinate, name: $0.name, description: $0.desc) }
            
            return AuthoredActivityContent(id: ext.identifier,
                                           type: actType,
                                           name: name,
                                           creator: creator,
                                           locale: ext.locale,
                                           availability: ext.availability,
                                           expires: ext.expires,
                                           image: imageURL,
                                           desc: description,
                                           waypoints: wpts,
                                           pois: pois)
            
        default:
            return nil
        }
    }
    
    /// Parses a list of GPXWaypoints into POIWaypoints and AnnotationWaypoints.
    ///
    /// - Parameter waypoints: an array of GPXWaypoints
    /// - Returns: an array of POIWaypoints and an array of AnnotationWaypoints
    private static func waypoints(from waypoints: [GPXWaypoint]) -> [ActivityWaypoint] {
        let imageMimeTypes = Set(["image/jpeg", "image/jpg", "image/png"])
        let audioMimeTypes = Set(["audio/mpeg", "audio/x-m4a"])
        
        return waypoints.map { wpt in
            let links = wpt.extensions?.soundscapeLinkExtensions?.links
            
            let parsedImages = links?.filter({ imageMimeTypes.contains($0.mimetype) })
                .compactMap { (link) -> ActivityWaypointImage? in
                    guard let url = URL(string: link.href) else {
                        return nil
                    }
                    
                    return ActivityWaypointImage(url: url, altText: link.text)
                }
            
            let parsedAudioClips = links?.filter({ audioMimeTypes.contains($0.mimetype) })
                .compactMap { (link) -> ActivityWaypointAudioClip? in
                    guard let url = URL(string: link.href) else {
                        return nil
                    }
                    
                    return ActivityWaypointAudioClip(url: url, description: link.text)
                }
            
            let allAnnotations = wpt.extensions?.soundscapeAnnotationExtensions?.annotations
            let departure = allAnnotations?.first(where: { $0.type == "departure" })?.content
            let arrival = allAnnotations?.first(where: { $0.type == "arrival" })?.content
            
            return ActivityWaypoint(coordinate: wpt.coordinate,
                                    name: wpt.name,
                                    description: wpt.desc,
                                    departureCallout: departure,
                                    arrivalCallout: arrival,
                                    images: parsedImages ?? [],
                                    audioClips: parsedAudioClips ?? [])
        }
    }
}

// MARK: - Custom String Convertible

extension AuthoredActivityContent: CustomStringConvertible {
    var description: String {
        var desc = "Authored Activity: \n\n"
        
        if waypoints.count > 0 {
            desc.append("\n\tRoute Waypoints:\n")
            
            for (index, wpt) in waypoints.enumerated() {
                let loc = "\(wpt.coordinate.latitude), \(wpt.coordinate.longitude)"
                let hasDescription = wpt.description != nil ? "has desc" : "no desc"
                let hasImage = wpt.images.count > 0 ? "has images" : "no images"
                let hasAudio = wpt.audioClips.count > 0 ? "has audio clips" : "no audio clips"
                
                if let name = wpt.name {
                    desc.append("\t\t\(index + 1). \(name) (\(loc)), \(hasDescription), \(hasImage), \(hasAudio)\n")
                } else {
                    desc.append("\t\t\(index + 1). Unnamed waypoint at (\(loc)), \(hasDescription), \(hasImage), \(hasAudio)")
                }
            }
        } else {
            desc.append("\n\tNo Route Waypoints\n")
        }
        
        if pois.count > 0 {
            desc.append("\n\tActivity POIs:\n")
            
            for (index, wpt) in pois.enumerated() {
                let loc = "\(wpt.coordinate.latitude), \(wpt.coordinate.longitude)"
                let hasDescription = wpt.description != nil ? "has desc" : "no desc"
                desc.append("\t\t\(index + 1). \(name) (\(loc)), \(hasDescription)\n")
            }
        } else {
            desc.append("\n\tNo POIs\n")
        }

        return desc
    }
}

extension ActivityPOI: POI {
    var key: String {
        return id.uuidString
    }
    
    var localizedName: String {
        return name
    }
    
    var superCategory: String {
        return SuperCategory.authoredActivity.rawValue
    }
    
    var addressLine: String? {
        return nil
    }
    
    var streetName: String? {
        return nil
    }
    
    var centroidLatitude: CLLocationDegrees {
        return coordinate.latitude
    }
    
    var centroidLongitude: CLLocationDegrees {
        return coordinate.longitude
    }
    
    func contains(location: CLLocationCoordinate2D) -> Bool {
        return coordinate == location
    }
    
    func closestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocation {
        return CLLocation(coordinate)
    }
    
    func distanceToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDistance {
        return coordinate.distance(from: location.coordinate)
    }
    
    func bearingToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDirection {
        return location.coordinate.bearing(to: coordinate)
    }
}

// Allow audio clips to be identified by their URL (no two audio clips in the same activity should have the same URL)
extension ActivityWaypointAudioClip: Identifiable {
    var id: String {
        return url.path
    }
}
