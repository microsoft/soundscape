//
//  CLLocation+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import GLKit

extension CLLocation {
    
    convenience init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    /// Convenience method to create a location with a custom timestamp
    func with(timestamp: Date) -> CLLocation {
        return CLLocation(coordinate: self.coordinate,
                          altitude: self.altitude,
                          horizontalAccuracy: self.horizontalAccuracy,
                          verticalAccuracy: self.verticalAccuracy,
                          course: self.course,
                          speed: self.speed,
                          timestamp: timestamp)
    }
    
    /// Convenience method to create a location with custom speed
    func with(speed: CLLocationSpeed) -> CLLocation {
        return CLLocation(coordinate: self.coordinate,
                          altitude: self.altitude,
                          horizontalAccuracy: self.horizontalAccuracy,
                          verticalAccuracy: self.verticalAccuracy,
                          course: self.course,
                          speed: speed,
                          timestamp: self.timestamp)
    }
    
    /// Convenience method to create a location with custom course
    func with(course: CLLocationSpeed) -> CLLocation {
        return CLLocation(coordinate: self.coordinate,
                          altitude: self.altitude,
                          horizontalAccuracy: self.horizontalAccuracy,
                          verticalAccuracy: self.verticalAccuracy,
                          course: course,
                          speed: self.speed,
                          timestamp: self.timestamp)
    }
    
    /// A convenience method to calculate the breading of one location's coordinate to another.
    /// See `bearing(to coordinate: CLLocationCoordinate2D)` in `CLLocationCoordinate2D`.
    func bearing(to location: CLLocation) -> CLLocationDirection {
        return self.coordinate.bearing(to: location.coordinate)
    }
    
    /// Returns a value which indicates whether the location's `course` value is directing to a coordinate.
    ///
    /// - Parameters:
    ///   - coordinate: The reference coordinate.
    ///   - angularWindowRange: The maximum allowed range to be considered 'traveling towards'.
    /// - Returns: `true` if the location's `course` value is directing to a coordinate.
    ///
    /// - note: The location's `course` and `angularWindowRange` values must be valid (equal to or greater than 0).
    /// ```
    /// // \    x    /  - Coordinate
    /// //  \       /
    /// //   \     /    - \/ Angular window range
    /// //    \   /
    /// //      ↑       - Course
    /// //      o       - Location
    /// ```
    func isTraveling(towards coordinate: CLLocationCoordinate2D, angularWindowRange: Double) -> Bool {
        guard course >= 0 && angularWindowRange >= 0 else {
            return false
        }
        
        let bearingToCoordinate = self.coordinate.bearing(to: coordinate)
        
        guard let directionRange = DirectionRange(direction: bearingToCoordinate, windowRange: angularWindowRange) else {
            return false
        }
        
        return directionRange.contains(course)
    }
    
}

extension Array where Element == CLLocation {
    
    /// Adjusts the speed and timestamp of the location objects to the average walking speed.
    /// - note: see `transform(speed: CLLocationSpeed)`.
    func transformToAverageWalkingSpeed() -> [CLLocation] {
        return self.transform(speed: CLLocationSpeed.averageWalkingSpeed)
    }
    
    /// Adjusts the speed of the location objects.
    /// - note: This also alters the timestamps of the location objects (starting from the
    ///         second location) to accommodate the new speed.
    /// - note: `speed` must be greater than zero.
    /// - complexity: O(*n*), where *n* is the length of the array.
    func transform(speed: CLLocationSpeed) -> [CLLocation] {
        guard speed > 0.0, self.count > 1 else {
            return self
        }
        
        var locations = [CLLocation]()
        for (index, location) in self.enumerated() {
            if index == 0 {
                locations.append(location.with(speed: speed))
                continue
            }
            
            let prevLocation = locations[index-1]
            let distance = location.distance(from: prevLocation)
            let updatedLocation: CLLocation
            
            if distance > 0.0 {
                let interval = distance/speed as TimeInterval
                let updatedTimestamp = prevLocation.timestamp.addingTimeInterval(interval)
                updatedLocation = location.with(timestamp: updatedTimestamp).with(speed: speed)
            } else {
                let updatedTimestamp = prevLocation.timestamp.addingTimeInterval(1.0)
                updatedLocation = location.with(timestamp: updatedTimestamp).with(speed: 0.0)
            }
            
            locations.append(updatedLocation)
        }
        
        return locations
    }
    
}

extension CLLocationCoordinate2D {
    
    var isValidLocationCoordinate: Bool {
        return CLLocationCoordinate2DIsValid(self) && self != CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
            .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    
    /// Returns a compass bearing (in the range 0...360) to the specified coordinate.
    ///
    /// - Parameters:
    ///   - coordinate: The reference coordinate.
    /// - Returns: Returns a compass bearing (in the range 0...360) to the specified coordinate.
    ///
    /// - note: See: http://www.movable-type.co.uk/scripts/latlong.html
    ///
    /// Illustration:
    /// ```
    /// // x      - self (current coordinate)
    /// //   ↘︎    - bearing
    /// //     x  - other coordinate
    /// ```
    func bearing(to coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        // Check that the coordinates are valid
        guard self.isValidLocationCoordinate, coordinate.isValidLocationCoordinate else {
            return -1
        }
        
        // Check if the coordinates are the same
        guard self != coordinate else {
            return 0
        }
        
        let startLatitude = self.latitude.degreesToRadians
        let startLongitude = self.longitude.degreesToRadians

        let endLatitude = coordinate.latitude.degreesToRadians
        let endLongitude = coordinate.longitude.degreesToRadians

        let dLongitude = endLongitude - startLongitude
        let cosEndLatitude = cos(endLatitude)

        let y = sin(dLongitude) * cosEndLatitude
        let x = cos(startLatitude) * sin(endLatitude) - sin(startLatitude) * cosEndLatitude * cos(dLongitude)
        let bearing = atan2(y, x).radiansToDegrees

        return fmod(bearing + 360.0, 360.0)
    }
    
    /// Returns the destination point from `self` having travelled the given distance on the given bearing.
    /// - Parameters:
    ///   - distance: Distance travelled.
    ///   - bearing: Initial bearing in degrees from north.
    /// - Returns: Destination point.
    /// - note: Source: http://www.movable-type.co.uk/scripts/latlong.html
    func destination(distance: CLLocationDistance, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        let δ = distance / GeometryUtils.earthRadius
        let θ = bearing.degreesToRadians
        
        let φ1 = self.latitude.degreesToRadians
        let λ1 = self.longitude.degreesToRadians
        
        let sinφ2 = sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ)
        let φ2 = asin(sinφ2)
        let y = sin(θ) * sin(δ) * cos(φ1)
        let x = cos(δ) - sin(φ1) * sinφ2
        let λ2 = λ1 + atan2(y, x)
        
        let latitude = φ2.radiansToDegrees
        let longitude = λ2.radiansToDegrees
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Returns a coordinate that is located between two coordinates, at a specific distance.
    /// - Parameters:
    ///   - coordinate: The reference coordinate.
    ///   - distance: The reference distance.
    /// - Returns: Destination coordinate.
    func coordinateBetween(coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) -> CLLocationCoordinate2D {
        return self.destination(distance: distance, bearing: self.bearing(to: coordinate))
    }
    
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.equalTo(coordinate: rhs, threshold: 0.0000009)
    }
    
    private func equalTo(coordinate: CLLocationCoordinate2D, threshold: CLLocationDegrees) -> Bool {
        return fabs(self.latitude - coordinate.latitude) <= threshold && fabs(self.longitude - coordinate.longitude) <= threshold
    }
}

extension CLLocationCoordinate2D: CustomStringConvertible {
    public var description: String {
        return "(\(latitude), \(longitude))"
    }
}

extension CLHeading {
    // Apple documentation: If the `headingAccuracy` property contains a negative value, the value in `magneticHeading` should be considered unreliable.
    var isValid: Bool {
        return self.headingAccuracy.isValid
    }
}

extension CLLocationDirection {
    
    // MARK: Compass Directions
    
    static let north: CLLocationDirection = 0.0
    static let east: CLLocationDirection = 90.0
    static let south: CLLocationDirection = 180.0
    static let west: CLLocationDirection = 270.0
    
    // MARK: Relative Directions
    
    static let ahead: CLLocationDirection = 0.0
    static let right: CLLocationDirection = 90.0
    static let behind: CLLocationDirection = 180.0
    static let left: CLLocationDirection = 270.0
    
    /// A negative value indicates an invalid direction.
    var isValid: Bool {
        return self >= 0
    }
    
    /// The relative bearing (clockwise angle) from a direction to another given direction (measured in degrees).
    /// The result is normalized between 0° and 360°.
    ///
    /// Examples:
    /// - 45°, bearing to 135° => 90°
    /// - 315°, bearing to 15° => 60°
    func bearing(to direction: CLLocationDirection) -> CLLocationDirection {
        return direction.add(degrees: -self)
    }
    
    /// Adds the `degrees` value to the current value.
    /// The result is normalized between 0° and 360°.
    ///
    /// Examples:
    /// - 45°, adding 90° => 135°
    /// - 315°, adding 60° => 15°
    /// - 10°, adding -90° => 280°
    func add(degrees: Double) -> CLLocationDirection {
        return fmod(self + degrees + 360.0, 360.0)
    }
    
}

extension CLLocationSpeed {
    static let averageWalkingSpeed: CLLocationSpeed = 1.4
}

extension Double {
    
    var degreesToRadians: Double {
        return convert(from: UnitAngle.degrees, to: UnitAngle.radians)
    }
    
    var radiansToDegrees: Double {
        return convert(from: UnitAngle.radians, to: UnitAngle.degrees)
    }
    
    private func convert(from: UnitAngle, to: UnitAngle) -> Double {
        return Measurement(value: self, unit: from).converted(to: to).value
    }
    
}

extension Double {
    /// Utility to format degrees with two decimal places and a degree symbol.
    var formattedDegrees: String {
        return String(format: "%.02f°", self)
    }
}

extension Double {
    func angularDifference(from degree: Double) -> Double {
        // Make sure both degrees are valid
        guard self != -1, degree != -1 else {
            return -1
        }
        
        return max(self, degree) - min(self, degree)
    }
}
