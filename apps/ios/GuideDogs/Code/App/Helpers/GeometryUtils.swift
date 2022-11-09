//
//  GeometryUtils.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

/// Should contain two objects: latitude and longitude
typealias GAPoint = [CLLocationDegrees]

/// Should contain one or more points
typealias GALine = [GAPoint]

/// Should contain one or more lines
typealias GAMultiLine = [GALine]

// Should contain one or more multi lines
typealias GAMultiLineCollection = [GAMultiLine]

class GeometryUtils {
    
    static let maxRoadDistanceForBearingCalculation: CLLocationDistance = 25.0

    static let earthRadius = Double(6378137)
    
    /// Parses a GeoJSON string and returns the coordinates and type values.
    static func coordinates(geoJson: String) -> (type: GeometryType?, points: [Any]?) {
        guard !geoJson.isEmpty, let jsonObject = GDAJSONObject(string: geoJson) else {
                return (nil, nil)
        }
        
        let geometryType: GeometryType?
        if let typeString = jsonObject.string(atPath: "type") {
            geometryType = GeometryType(rawValue: typeString)
        } else {
            geometryType = nil
        }
        
        guard let geometry = jsonObject.array(atPath: "coordinates") else {
            return (geometryType, nil)
        }
        
        return (geometryType, geometry)
    }
    
    /// Returns whether a coordinate lies inside of path.
    /// The path is always considered closed, regardless of whether the last point equals the first or not.
    static func geometryContainsLocation(location: CLLocationCoordinate2D, coordinates: [CLLocationCoordinate2D]) -> Bool {
        guard coordinates.count > 0 else {
            return false
        }
        
        // Construct the polygon as a CGPath
        let path = CGMutablePath()
        
        var (pixelX, pixelY) = VectorTile.getPixelXY(latitude: coordinates.first!.latitude, longitude: coordinates.first!.longitude, zoom: 16)
        path.move(to: CGPoint(x: pixelX, y: pixelY))
        
        for coordinate in coordinates {
            (pixelX, pixelY) = VectorTile.getPixelXY(latitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 16)
            path.addLine(to: CGPoint(x: pixelX, y: pixelY))
        }
        
        // Check if we need to add a coordinate for a closed path
        if coordinates.last! != coordinates.first! {
            (pixelX, pixelY) = VectorTile.getPixelXY(latitude: coordinates.first!.latitude, longitude: coordinates.first!.longitude, zoom: 16)
        }
        path.move(to: CGPoint(x: pixelX, y: pixelY))
        
        // Check if the point is inside the polygon
        (pixelX, pixelY) = VectorTile.getPixelXY(latitude: location.latitude, longitude: location.longitude, zoom: 16)
        return path.contains(CGPoint(x: pixelX, y: pixelY))
    }
    
    /// Calculates the bearing of a coordinates path.
    ///
    /// Calculates the bearing from the first coordinate on a path (i.e. an array of coordinates) to the furthest
    /// point on that path which is no further away from the first point than the specified `maxDistance`.
    ///
    /// - Parameters:
    ///   - path: The reference path.
    ///   - maxDistance: The max distance for calculating the reference coordinate along the path.
    /// - Returns: The bearing of a coordinates path.
    ///
    /// - note: The path most have more than one coordinate.
    ///
    /// Illustration:
    /// ```
    /// // A * *          - (A) first coordinate
    /// //     * * *
    /// //       ↘︎ *      - (↘︎) bearing from A to B
    /// //         B      - (B) max distance coordinate
    /// //         * * C  - (C) last coordinate
    /// ```
    static func pathBearing(for path: [CLLocationCoordinate2D], maxDistance: CLLocationDistance = CLLocationDistanceMax) -> CLLocationDirection? {
        guard let firstCoordinate = path.first else {
            print("[GAPathBearing] Error: path has no coordinates")
            return nil
        }
        
        guard let referenceCoordinate = referenceCoordinate(on: path, for: maxDistance) else {
            print("[GAPathBearing] Error: could not calculate reference coordinate")
            return nil
        }
        
        return firstCoordinate.bearing(to: referenceCoordinate)
    }
    
    ///  Returns the sub-coordinates from a coordinate on a path until the end or start of the path.
    ///
    /// - Parameters:
    ///     - path: The reference path.
    ///     - coordinate: The reference coordinate.
    ///     - reversedDirection: If `true` is passed, the returned sub-coordinates will be
    ///     cauculated from the reference coordinate to the start of the path.
    /// - Returns: The sub-coordinates from a coordinate on a path until the end or start of the path.
    static func split(path: [CLLocationCoordinate2D],
                      atCoordinate coordinate: CLLocationCoordinate2D,
                      reversedDirection: Bool = false) -> [CLLocationCoordinate2D] {
        guard let coordinateIndex = path.firstIndex(of: coordinate) else {
            return []
        }
        
        return reversedDirection ?                       // Illustration: numbers are coordinates, * is the root coordinate.
            Array(path[...coordinateIndex].reversed()) : // [1, 2, 3, *, 5, 6, 7] → [*, 3, 2, 1]
            Array(path[coordinateIndex...])              // [1, 2, 3, *, 5, 6, 7] → [*, 5, 6, 7]
    }
    
    /// Rotates the order of the coordinates in a circular path so that the specified coordinate is the first/last coordinate
    ///
    /// If the input path is [1, 2, 3, 4, 5, 1] and the coordinate to rotate about is 3, then the resulting path will be
    /// [3, 4, 5, 1, 2, 3] (or [3, 2, 1, 5, 4, 3] if the direction is reversed).
    ///
    /// - Parameters:
    ///   - path: The circular path to rotate. If a non-circular path is provided, an empty array will be returned
    ///   - coordinate: The reference coordinate
    ///   - reversedDirection: If `true` is passed, the returned coordinates will be reversed
    /// - Returns: A rotated version of the circular path passed in
    static func rotate(circularPath path: [CLLocationCoordinate2D],
                       atCoordinate coordinate: CLLocationCoordinate2D,
                       reversedDirection: Bool = false) -> [CLLocationCoordinate2D] {
        guard pathIsCircular(path), let coordinateIndex = path.firstIndex(of: coordinate) else {
            return []
        }
        
        guard coordinateIndex != 0 else {
            if reversedDirection {
                return path.reversed()
            } else {
                return path
            }
        }
        
        let back: [CLLocationCoordinate2D] = Array(path[coordinateIndex ..< (path.count - 1)]) // ..< so we don't include the current start/end coordinate twice
        let front: [CLLocationCoordinate2D] = Array(path[0 ... coordinateIndex]) // ... so we start and end the new order with the same coordinate
        
        return reversedDirection ? (back + front).reversed() : back + front
    }
    
    ///  Returns `true` if the path is a circular path (the first coordinate is equal to the last coordinate,
    ///  and there are more than 2 coordinates).
    ///
    /// - Parameters:
    ///   - path: The reference path.
    /// - Returns: `true` if the path is a circular path, `false` otherwise.
    static func pathIsCircular(_ path: [CLLocationCoordinate2D]) -> Bool {
        guard path.count > 2, let first = path.first, let last = path.last else {
            return false
        }
        
        return first == last
    }
    
    ///  Returns the distance of a coordinate path
    ///
    /// - Parameters:
    ///   - path: The reference path.
    /// - Returns: The distance of a coordinate path
    static func pathDistance(_ path: [CLLocationCoordinate2D]) -> CLLocationDistance {
        guard path.count > 1 else {
            return 0
        }
        
        var distance: CLLocationDistance = 0
        
        for index in 0 ..< path.count-1 {
            distance += path[index].distance(from: path[index+1])
        }
        
        return distance
    }
    
    /// Calculates a coordinate on a path at a target distance from the path's first coordinate.
    /// - note: If the target distance is greater than the path distance, the last path coordinate is returned.
    /// - note: If the target distance is between two coordinates on the path, a synthesized coordinate between the coordinates is returned.
    /// - note: If the target distance is smaller or equal to zero, the first path coordinate is returned.
    static func referenceCoordinate(on path: [CLLocationCoordinate2D], for targetDistance: CLLocationDistance) -> CLLocationCoordinate2D? {
        guard !path.isEmpty else {
            return nil
        }
        
        if path.count == 1 || targetDistance <= 0 {
            return path.first
        }
        
        if targetDistance == CLLocationDistanceMax {
            return path.last
        }
                
        var totalDistance = CLLocationDistance(0)
        
        for index in 0 ..< path.count-1 {
            let coord1 = path[index]
            let coord2 = path[index+1]
            
            let coordDistance = coord1.distance(from: coord2)
            totalDistance += coordDistance
            
            if totalDistance == targetDistance {
                return coord2
            }
            
            if totalDistance > targetDistance {
                // The target coordinate is between two coordinates, so we synthesize it
                let prevTotalDistance = totalDistance - coordDistance
                let prevTotalDistanceToTargetDistance = targetDistance - prevTotalDistance
                
                return coord1.coordinateBetween(coordinate: coord2, distance: prevTotalDistanceToTargetDistance)
            }
        }
        
        return path.last
    }
    
    static func squaredDistance(location: CLLocationCoordinate2D,
                                start: CLLocationCoordinate2D,
                                end: CLLocationCoordinate2D,
                                zoom: UInt) -> (CLLocationDistance, CLLocationDegrees, CLLocationDegrees) {
        // Get the points of the geocoordinates in the pixel space
        let (startX, startY) = VectorTile.getPixelXY(latitude: start.latitude,
                                                     longitude: start.longitude,
                                                     zoom: zoom)
        let (endX, endY) = VectorTile.getPixelXY(latitude: end.latitude,
                                                 longitude: end.longitude,
                                                 zoom: zoom)
        let (userX, userY) = VectorTile.getPixelXY(latitude: location.latitude,
                                                   longitude: location.longitude,
                                                   zoom: zoom)
        
        let (aX, aY) = (Double(startX), Double(startY))
        let (bX, bY) = (Double(endX), Double(endY))
        let (cX, cY) = (Double(userX), Double(userY))
        
        if aX == bX && aY == bY {
            // return squared distance (in pixels)
            return ((cX - aX) * (cX - aX) + (cY - aY) * (cY - aY), start.latitude, start.longitude)
        }
        
        // Calculate the vectors
        let (abX, abY) = (bX - aX, bY - aY)
        let (acX, acY) = (cX - aX, cY - aY)
        
        // Calculate the projection of vector ac onto the line L = { cv | c in R } where v is the vector ab above
        let abDotAc = abX * acX + abY * acY // x dot v
        let abDotAb = abX * abX + abY * abY // v dot v
        let coeff = abDotAc / abDotAb
        
        var (projX, projY) = (aX + abX * coeff, aY + abY * coeff)
        
        // Bound the projection to the segment from a to b (the projection was calculated based on the
        // line defined by a and b, and the projected point can therefore be outside of the segment
        // between a and b but still on the same line).
        if aX != bX {
            let (leftX, leftY) = aX < bX ? (aX, aY) : (bX, bY)
            let (rightX, rightY) = aX > bX ? (aX, aY) : (bX, bY)
            
            if projX <= aX && projX <= bX {
                // Bound projection to point a
                (projX, projY) = (leftX, leftY)
            } else if projX >= aX && projX >= bX {
                // Bound projection to point b
                (projX, projY) = (rightX, rightY)
            }
        } else {
            let (leftX, leftY) = aY < bY ? (aX, aY) : (bX, bY)
            let (rightX, rightY) = aY > bY ? (aX, aY) : (bX, bY)
            
            if projY <= aY && projY <= bY {
                // Bound projection to point a
                (projX, projY) = (leftX, leftY)
            } else if projY >= aY && projY >= bY {
                // Bound projection to point b
                (projX, projY) = (rightX, rightY)
            }
        }
        
        // return squared distance to projected point (in pixels)
        let (lat, lon) = VectorTile.getLatLong(pixelX: Int(projX), pixelY: Int(projY), zoom: zoom)
        return ((cX - projX) * (cX - projX) + (cY - projY) * (cY - projY), lat, lon)
    }
    
    static func closestEdge(from coordinate: CLLocationCoordinate2D, on polygon: GAMultiLine) -> CLLocation? {
        var coordinates: [CLLocationCoordinate2D] = []
        
        // Transform to a continuous coordinates path
        for line in polygon {
            for point in line {
                coordinates.append(point.toCoordinate())
            }
        }
                
        return closestEdge(from: coordinate, on: coordinates)
    }
    
    static func closestEdge(from coordinate: CLLocationCoordinate2D, on path: [CLLocationCoordinate2D]) -> CLLocation? {
        // Used to calculate distance to a point on a polygon
        let zoomLevel: UInt = 23
        let res: Double = VectorTile.groundResolution(latitude: coordinate.latitude, zoom: zoomLevel)
        
        var closestLocation: CLLocation?
        var minimumDistance = CLLocationDistanceMax
        
        for i in 0..<path.count - 1 {
            // `start` and `end` of line segment between coordinates
            let start = path[i]
            let end = path[i+1]
            
            guard start.latitude != end.latitude || start.longitude != end.longitude else {
                continue
            }
            
            // Calculate the minimum squared distance from user location to line segment
            // Distance is calculated in pixel space
            let (distanceSq, lat, long) = GeometryUtils.squaredDistance(location: coordinate,
                                                                        start: start,
                                                                        end: end,
                                                                        zoom: zoomLevel)
            
            // Translate pixel distance to meters
            let distance = sqrt(distanceSq) * res
            
            if distance < minimumDistance {
                closestLocation = CLLocation(latitude: lat, longitude: long)
                minimumDistance = distance
            }
        }
        
        return closestLocation
    }
    
    ///  Returns the interpolated path between coordinates in a coordinates array. The interpolated path
    ///  (coordinates between the original coordinates) will have a fixed distance of `distance`.
    ///
    /// Illustration:
    /// ```
    /// Original path:
    /// *-------------------*------*-*--------*
    /// Interpolated path:
    /// *----*----*----*----*----*-*-*----*---*
    /// ```
    ///
    /// - Parameters:
    ///     - start: The start coordinate.
    ///     - end: The end coordinate.
    ///     - distance: The fixed distance to use between the interpolated coodinates.
    /// - Returns: An coordinates path including the original coordinates and any coordiantes between
    /// them with a fixed distance of `distance`.
    static func interpolateToEqualDistance(coordinates: [CLLocationCoordinate2D],
                                           distance targetDistance: CLLocationDistance) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 1 else {
            return coordinates
        }
        
        var totalInterpolation: [CLLocationCoordinate2D] = []
        
        for index in 0...coordinates.count-2 {
            let coordinate = coordinates[index]
            let nextCoordinate = coordinates[index+1]
            
            var interpolation = GeometryUtils.interpolateToEqualDistance(start: coordinate,
                                                                         end: nextCoordinate,
                                                                         distance: targetDistance)
            
            if index != coordinates.count-2 {
                // For every interpolation (except the last) we remove the last coordinate.
                // This is because the next interpolation will include it as the first.
                interpolation.removeLast()
            }
            
            totalInterpolation.append(contentsOf: interpolation)
        }
        
        return totalInterpolation
    }
    
    ///  Returns the interpolated path between two coordinates. The interpolated path
    ///  (coordinates between `start` and `end`) will have a fixed distance of `distance`.
    ///
    /// Illustration:
    /// ```
    /// start             end
    /// *-------------------*
    /// *----*----*----*----*
    /// ```
    ///
    /// - Parameters:
    ///     - start: The start coordinate.
    ///     - end: The end coordinate.
    ///     - distance: The fixed distance to use between the interpolated coodinates.
    /// - Returns: An coordinates path including `start`, `end` and any coordiantes between
    /// them with a fixed distance of `distance`.
    static func interpolateToEqualDistance(start: CLLocationCoordinate2D,
                                           end: CLLocationCoordinate2D,
                                           distance targetDistance: CLLocationDistance) -> [CLLocationCoordinate2D] {
        let totalDistance = start.distance(from: end)
        
        guard totalDistance > targetDistance else {
            return [start, end]
        }
        
        var coordinates = [start]
        var remainingDistance = totalDistance
        
        // We repeatedly create coordinates at fixed distances until we reach the target distance
        repeat {
            guard let prevCoordinate = coordinates.last else { break }
            
            let currentCoordinate = prevCoordinate.coordinateBetween(coordinate: end, distance: targetDistance)
            coordinates.append(currentCoordinate)
            
            remainingDistance = currentCoordinate.distance(from: end)
        } while remainingDistance > targetDistance
        
        coordinates.append(end)
        
        return coordinates
    }
    
}

// MARK: - Centroid Calculations

extension GeometryUtils {
    
    /// Returns a generated coordinate representing the mean center of a given array of coordinates.
    static func centroid(geoJson: String) -> CLLocationCoordinate2D? {
        guard let points = GeometryUtils.coordinates(geoJson: geoJson).points else {
            return nil
        }
        
        // Check if `points` contains one point (e.g. point)
        if let point = points as? GAPoint {
            return point.toCoordinate()
        }
        
        // Check if `points` contains an array of points (e.g. line, polygon)
        if let points = points as? GALine {
            return GeometryUtils.centroid(coordinates: points.toCoordinates())
        }
        
        // Check if `points` contains a two dimensional array of points (e.g. lines, polygons)
        if let points = points as? GAMultiLine {
            let flattened = Array(points.toCoordinates().joined())
            return GeometryUtils.centroid(coordinates: flattened)
        }
        
       return nil
    }
    
    /// Returns a generated coordinate representing the mean center of a given array of `CLLocation` objects.
    /// - Note: See `centroid(locations: [CLLocation]) -> CLLocationCoordinate2D?`
    static func centroid(locations: [CLLocation]) -> CLLocationCoordinate2D? {
        return GeometryUtils.centroid(coordinates: locations.map { (location) -> CLLocationCoordinate2D in
            return location.coordinate
        })
    }
    
    /// Returns a generated coordinate representing the mean center of a given array of `CLLocationCoordinate2D` objects.
    ///
    /// The centroid calculation is done by creating a bound box for the coordinates and extracting the center,
    /// this means that any geometrical shape is acceptable.
    /// - Note: In practice, for extremely irregular shapes, this can lead to center coordinates not inside the shape.
    static func centroid(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        if coordinates.isEmpty {
            return nil
        }
        
        if coordinates.count == 1 {
            return coordinates[0]
        }
        
        // We start with the widest bound box available for coordinates.
        // We then loop thru the given coordinates and narrow it.
        // This creates a minimum bounding box that contains all the coordinates.
        var minLat: CLLocationDegrees = 90.0
        var maxLat: CLLocationDegrees = -90.0
        var minLon: CLLocationDegrees = 180.0
        var maxLon: CLLocationDegrees = -180.0
        
        for coordinate in coordinates {
            let lat = coordinate.latitude
            let long = coordinate.longitude
            
            if lat < minLat {
                minLat = lat
            }
            if long < minLon {
                minLon = long
            }
            if lat > maxLat {
                maxLat = lat
            }
            if long > maxLon {
                maxLon = long
            }
        }
        
        // Create a span that represents the distance (delta) between the top and bottom (north-to-south) edges,
        // and the right and left (east-to-west) edges of the box.
        let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
        
        // Return the generated center coordinate for the bounding box
        return CLLocationCoordinate2DMake((maxLat - span.latitudeDelta / 2.0), (maxLon - span.longitudeDelta / 2.0))
    }
    
}

// MARK: - Transforming Points to Coordinates

extension Array where Element == Double {
    /// Transform to a `CLLocationCoordinate2D` object.
    func toCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self[1], self[0])
    }
}

extension Array where Element == [Double] {
    /// Transform to an array of `CLLocationCoordinate2D` objects.
    func toCoordinates() -> [CLLocationCoordinate2D] {
        return self.map({ (point) -> CLLocationCoordinate2D in
            point.toCoordinate()
        })
    }
}

extension Array where Element == [[Double]] {
    /// Transform to multiple arrays of `CLLocationCoordinate2D` objects.
    func toCoordinates() -> [[CLLocationCoordinate2D]] {
        return self.map({ (points) -> [CLLocationCoordinate2D] in
            points.toCoordinates()
        })
    }
}

extension Array where Element == [[[Double]]] {
    /// Transform to multiple arrays of `CLLocationCoordinate2D` objects.
    func toCoordinates() -> [[[CLLocationCoordinate2D]]] {
        return self.map({ (points) -> [[CLLocationCoordinate2D]] in
            points.toCoordinates()
        })
    }
}
