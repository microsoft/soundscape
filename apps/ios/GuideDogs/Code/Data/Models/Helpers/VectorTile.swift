//
//  VectorTile.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// VectorTile is an object which identifies a single vector tile. This includes the x and y coordinates of
/// the tile in the tile space, and the zoom level which specifies that tile space. Note that this class does
/// not contain the actual POI contents of the tile (see TileData.swift).
class VectorTile: Hashable {
    enum VectorTileError: Error {
        case zoomValueOutOfRange
        case invalidQuadKeySequence
    }
    
    static let earthRadius = 6378137
    static let minLatitude = -85.05112878
    static let maxLatitude = 85.05112878
    static let minLongitude: Double = -180
    static let maxLongitude: Double = 180
    
    let x: Int
    let y: Int
    let zoom: UInt
    let quadKey: String
    let id: String
    
    private(set) lazy var polygon: [CLLocationCoordinate2D] = {
        let (startPixelX, startPixelY) = VectorTile.getPixelXY(tileX: self.x, tileY: self.y)
        let (endPixelX, endPixelY) = VectorTile.getPixelXY(tileX: self.x + 1, tileY: self.y + 1)
        
        let (startLat, startLon) = VectorTile.getLatLong(pixelX: startPixelX, pixelY: startPixelY, zoom: self.zoom)
        let (endLat, endLon) = VectorTile.getLatLong(pixelX: endPixelX, pixelY: endPixelY, zoom: self.zoom)
        
        return [CLLocationCoordinate2D(latitude: startLat, longitude: startLon),
                CLLocationCoordinate2D(latitude: startLat, longitude: endLon),
                CLLocationCoordinate2D(latitude: endLat, longitude: endLon),
                CLLocationCoordinate2D(latitude: endLat, longitude: startLon),
                CLLocationCoordinate2D(latitude: startLat, longitude: startLon)]
    }()
    
    /// Initializes a VectorTile object from a JSON object which must have keys "X", "Y", "ZoomLevel", "QuadKey", and "Id"
    ///
    /// - Parameter json: JSON object to parse
    init(JSON json: GDAJSONObject) {
        x = json.number(atPath: "X")!.intValue
        y = json.number(atPath: "Y")!.intValue
        zoom = json.number(atPath: "ZoomLevel")!.uintValue
        quadKey = json.string(atPath: "QuadKey")!
        id = json.string(atPath: "Id")!
    }
    
    /// Initializes a VectorTile object using a latitude, longitude, and zoom
    ///
    /// - Parameters:
    ///   - lat: Latitude
    ///   - lon: Longitude
    ///   - zoomLevel: Zoom level
    init(latitude lat: Double, longitude lon: Double, zoom zoomLevel: UInt) {
        let (pixelX, pixelY) = VectorTile.getPixelXY(latitude: lat, longitude: lon, zoom: zoomLevel)
        let (tileX, tileY) = VectorTile.getTileXY(pixelX: pixelX, pixelY: pixelY)
        
        x = tileX
        y = tileY
        zoom = zoomLevel
        
        do {
            let key = try VectorTile.getQuadKey(tileX: tileX, tileY: tileY, zoom: zoomLevel)
            
            quadKey = key
            id = key
        } catch {
            quadKey = ""
            id = ""
        }
    }
    
    /// Initializes a VectorTile object using the (x, y, zoom) coordinates of the tile in the tile space
    ///
    /// - Parameters:
    ///   - tileX: Tile's X coordinate
    ///   - tileY: Tile's Y coordinate
    ///   - zoomLevel: Tile's zoom level
    init(tileX: Int, tileY: Int, zoom zoomLevel: UInt) {
        x = tileX
        y = tileY
        zoom = zoomLevel
        
        do {
            let key = try VectorTile.getQuadKey(tileX: tileX, tileY: tileY, zoom: zoomLevel)
            
            quadKey = key
            id = key
        } catch {
            quadKey = ""
            id = ""
        }
    }
    
    /// Initializes a VectorTile object using a quadkey specifier
    ///
    /// - Parameter quad: Quadkey describing the vector tile x, y, and zoom
    init(quadKey quad: String) {
        do {
            (x, y, zoom) = try VectorTile.getTileXYZ(quadkey: quad)
        } catch {
            x = -1
            y = -1
            zoom = 0
        }
        
        quadKey = quad
        id = quad
    }
    
    /// Checks if two tiles are equivalent. Two tiles are equal if they have the same
    /// x, y, and zoom values.
    ///
    /// - Parameter lhs: First tile
    /// - Parameter rhs: Second tile
    static func == (lhs: VectorTile, rhs: VectorTile) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.zoom == rhs.zoom
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(zoom)
    }
    
    /// Calculates the set of tiles that cover a circular region around the specified location with the given radius
    ///
    /// - Parameters:
    ///   - location: The center of the region to search
    ///   - radius: The radius of the region to search
    /// - Returns: An array of tiles covering the searched region
    static func tilesForRegion(_ location: CLLocation, radius: CLLocationDistance, zoom zoomLevel: UInt) -> [VectorTile] {
        let (pixelX, pixelY) = getPixelXY(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        let radiusPixels = Int(radius / groundResolution(latitude: location.coordinate.latitude, zoom: zoomLevel))
        
        let startX = pixelX - radiusPixels
        let startY = pixelY - radiusPixels
        let endX = pixelX + radiusPixels
        let endY = pixelY + radiusPixels
        
        let (startTileX, startTileY) = getTileXY(pixelX: startX, pixelY: startY)
        let (endTileX, endTileY) = getTileXY(pixelX: endX, pixelY: endY)
        
        var tiles: [VectorTile] = []
        
        for y in startTileY...endTileY {
            for x in startTileX...endTileX {
                tiles.append(VectorTile(tileX: x, tileY: y, zoom: zoomLevel))
            }
        }
        
        return tiles
    }
    
    /// Returns the tile that a particular location resides within
    ///
    /// - Parameters:
    ///   - location: The center of the region to search
    ///   - zoom: The zoom level of the tile
    /// - Returns: The tile containing the location
    static func tileForLocation(_ location: CLLocation, zoom zoomLevel: UInt) -> VectorTile {
        let (pixelX, pixelY) = getPixelXY(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        
        let (x, y) = getTileXY(pixelX: pixelX, pixelY: pixelY)
        
        return VectorTile(tileX: x, tileY: y, zoom: zoomLevel)
    }
    
    /// Clips a value to the range [max, min]
    ///
    /// - Parameters:
    ///   - value: Value to clip
    ///   - minimum: Minimum value
    ///   - maximum: Maximum value
    /// - Returns: Clipped value
    static func clip(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        return min(max(value, minimum), maximum)
    }
    
    /// Returns the size of the map in pixels for the given zoom level
    ///
    /// - Parameter zoom: A zoom level (between 0 and 23)
    /// - Returns: Side length of the map in pixels
    static func mapSize(zoom: UInt) -> UInt {
        let base: UInt = 256
        return base << zoom
    }
    
    /// Determines the ground resolution (in meters per pixel) at a specified
    /// latitude and level of detail.
    ///
    /// - Parameters:
    ///   - latitude: Latitude (in degrees) at which to measure the ground resolution.
    ///   - zoom: Level of detail, from 1 (lowest detail) to 23 (highest detail).
    /// - Returns: The ground resolution, in meters per pixel.
    static func groundResolution(latitude: Double, zoom: UInt) -> Double {
        let clippedLat = clip(latitude, min: minLatitude, max: maxLatitude)
        return cos(clippedLat * .pi / 180.0) * 2 * .pi * Double(earthRadius) / Double(mapSize(zoom: zoom))
    }
    
    /// Calculates the pixel coordinate of the provided latitude and longitude location at the given zoom level
    ///
    /// - Parameters:
    ///   - latitude: Latitude value
    ///   - longitude: Longitude value
    ///   - zoomLevel: Zoom level
    /// - Returns: Pixe coordinate (x,y)
    static func getPixelXY(latitude: Double, longitude: Double, zoom zoomLevel: UInt) -> (x: Int, y: Int) {
        let lat = clip(latitude, min: minLatitude, max: maxLatitude)
        let lon = clip(longitude, min: minLongitude, max: maxLongitude)
        
        let sinLat = sin(lat * .pi / 180)
        let x = (lon + 180) / 360
        let y = 0.5 - log((1 + sinLat) / (1 - sinLat)) / (.pi * 4)
        
        let size = Double(mapSize(zoom: zoomLevel))
        
        let pixelX = Int(clip((x * size + 0.5), min: 0, max: (size - 1)))
        let pixelY = Int(clip((y * size + 0.5), min: 0, max: (size - 1)))
        
        return (pixelX, pixelY)
    }
    
    static func getPixelXYObjC(latitude: Double, longitude: Double, zoom zoomLevel: UInt) -> [String: Int] {
        let (x, y) = getPixelXY(latitude: latitude, longitude: longitude, zoom: zoomLevel)
        return ["x": x, "y": y]
    }
    
    /// Calculates the latitude and longitude of the provided pixel coordinate at the given zoom level
    ///
    /// - Parameters:
    ///   - pixelX: X coordinate of the pixel
    ///   - pixelY: Y coordinate of the pixel
    ///   - zoomLevel: Zoom level of the pixel
    /// - Returns: Latitude and longitude of the pixel
    static func getLatLong(pixelX: Int, pixelY: Int, zoom zoomLevel: UInt) -> (lat: Double, lon: Double) {
        let size = Double(mapSize(zoom: zoomLevel))
        
        let x = (clip(Double(pixelX), min: 0, max: Double(size - 1)) / size) - 0.5
        let y = 0.5 - (clip(Double(pixelY), min: 0, max: Double(size - 1)) / size)
        
        let lat = 90 - 360 * atan(exp(-y * 2 * .pi)) / .pi
        let lon = 360 * x
        
        return (lat, lon)
    }
    
    /// Calculates the coordinate of the tile containing the provided pixel coordinate
    ///
    /// - Parameters:
    ///   - pixelX: X coordinate of the pixel
    ///   - pixelY: Y coordinate of the pixel
    /// - Returns: Tile coordinate (x, y)
    static func getTileXY(pixelX: Int, pixelY: Int) -> (x: Int, y: Int) {
        return (pixelX / 256, pixelY / 256)
    }
    
    /// Calculates the pixel coordinate of the upper left corner of a vector tile
    ///
    /// - Parameters:
    ///   - tileX: X coordinate of the tile
    ///   - tileY: Y coordinate of the tile
    /// - Returns: Pixel coordinate (x, y)
    static func getPixelXY(tileX: Int, tileY: Int) -> (x: Int, y: Int) {
        return (tileX * 256, tileY * 256)
    }
    
    /// Checks if the provided (lat, lon) values are valid values.
    ///
    /// Note that latitudes are clipped to +-85.05112878 rather than the true +-90 in order to prevent
    /// singularities at the poles of the map and to let the map be a rectangle with the Mercator projection
    ///
    /// - Parameters:
    ///   - latitude: Latitude value to check
    ///   - longitude: Longitude value to check
    /// - Returns: True if the (lat, lon) values are valid
    static func isValidLocation(latitude: Double, longitude: Double) -> Bool {
        if latitude < -85.05112878 || latitude > 85.05112878 {
            return false
        }
        
        if longitude < -180.0 || longitude > 180.0 {
            return false
        }
        
        return true
    }
    
    /// Checks if the provided (X, Y, Zoom) values specify a valid tile
    ///
    /// - Parameters:
    ///   - tileX: X coordinate of the tile
    ///   - tileY: Y coordinate of the tile
    ///   - zoomLevel: Zoom level of the tile
    /// - Returns: True if the (X, Y, Zoom) values specify a valid tile
    static func isValidTile(x tileX: Int, y tileY: Int, zoom zoomLevel: UInt) -> Bool {
        let size = Int(mapSize(zoom: zoomLevel) / 256)
        
        let validX = tileX >= 0 && tileX < size
        let validY = tileY >= 0 && tileY < size
        
        return validX && validY
    }
    
    /// Generates a quadkey string from the tile X, Y coordinates and zoom level provided
    ///
    /// - Parameters:
    ///   - tileX: X coordinate of a tile
    ///   - tileY: Y coordinate of the tile
    ///   - zoomLevel: Zoom level of the tile
    /// - Returns: A quadkey string
    /// - Throws: Throws a VectorTileError.ZoomValueOutOfRange error if the zoom level is less than 0 or greater than 23
    static func getQuadKey(tileX: Int, tileY: Int, zoom zoomLevel: UInt) throws -> String {
        guard zoomLevel > 0 && zoomLevel < 24 else {
            throw VectorTileError.zoomValueOutOfRange
        }
        
        var quadkey = ""
        
        for level in (1...Int(zoomLevel)).reversed() {
            var digit: Int = 0
            let mask = 1 << (level - 1)
            
            if (tileX & mask) != 0 {
                digit += 1
            }
            
            if (tileY & mask) != 0 {
                digit += 2
            }
            
            quadkey += String(digit)
        }
        
        return quadkey
    }
    
    /// Given a quadkey string, this function parses and returns the tile X and Y coordinates and the zoom level specified by the quadkey.
    ///
    /// - Parameter quadkey: A string quadkey
    /// - Returns: A tuple containing the x, y, and zoom values
    /// - Throws: Throws a VectorTileError.InvalidQuadKeySequence error if the quadkey string is contains invalid characters
    static func getTileXYZ(quadkey: String) throws -> (x: Int, y: Int, zoom: UInt) {
        var x: Int = 0
        var y: Int = 0
        let zoom: Int = quadkey.count
        
        for level in (1...zoom).reversed() {
            let mask = 1 << (level - 1)
            let index = quadkey.index(quadkey.startIndex, offsetBy: zoom - level)
            
            switch quadkey[index] {
            case "0":
                break
                
            case "1":
                x |= mask
                
            case "2":
                y |= mask
                
            case "3":
                x |= mask
                y |= mask
                
            default:
                throw VectorTileError.invalidQuadKeySequence
            }
        }
        
        return (x, y, UInt(zoom))
    }
}
