//
//  GDASpatialDataResultEntity+Distance.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension GDASpatialDataResultEntity {
    
    func closestEntrance(from location: CLLocation) -> POI? {
        guard let entrances = entrances else {
            return nil
        }
        
        var closestEntrance: POI?
        var minimumDistance = CLLocationDistanceMax
        
        for entrance in entrances {
            let distance = entrance.distanceToClosestLocation(from: location)
            
            if distance < minimumDistance {
                closestEntrance = entrance
                minimumDistance = distance
            }
        }
        
        return closestEntrance
    }
    
    func closestEdge(from location: CLLocation) -> CLLocation? {
        guard let coordinates = coordinates else {
            return nil
        }
        // If we have coordinates, use those to update the distance and bearing,
        // otherwise, use the `latitude` and `longitude` properties
        
        var closestLocation: CLLocation?
        var minimumDistance = CLLocationDistanceMax
        
        if geometryType == .lineString || geometryType == .multiPoint {
            guard let coordinates = coordinates as? GALine else {
                return nil
            }
            
            for coordinate in coordinates {
                let lat = coordinate[1]
                let lon = coordinate[0]
                
                let newLocation = CLLocation(latitude: lat, longitude: lon)
                let distance = newLocation.distance(from: location)
                
                if distance < minimumDistance {
                    closestLocation = newLocation
                    minimumDistance = distance
                }
            }
        } else if geometryType == .multiLineString || geometryType == .polygon {
            guard let polygon = coordinates as? GAMultiLine else {
                return nil
            }
            
            closestLocation = GeometryUtils.closestEdge(from: location.coordinate, on: polygon)
        } else if geometryType == .multiPolygon {
            guard let polygons = coordinates as? GAMultiLineCollection else {
                return nil
            }
            
            for polygon in polygons {
                guard let newLocation = GeometryUtils.closestEdge(from: location.coordinate, on: polygon) else {
                    continue
                }
                
                let distance = newLocation.distance(from: location)
                
                if distance < minimumDistance {
                    closestLocation = newLocation
                    minimumDistance = distance
                }
            }
        }
        
        return closestLocation
    }
    
}
