//
//  TileData.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import RealmSwift

/// Point is a class that acts like CLLocationCoordinate2D, but it is hashable. This
/// class is only intended for use in TileData.findIntersections(...), hence the
/// fileprivate access specifier.
private class Point: Hashable {
    // MARK: Properties
    let lat: Double
    let lon: Double
    
    var description: String {
        return String(format: "(%.7f,%.7f)", self.lat, self.lon)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
    // MARK: Initializers
    
    init(latitude: Double, longitude: Double) {
        self.lat = latitude
        self.lon = longitude
    }
    
    // MARK: Static functions
    static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.description == rhs.description
    }
}

/// TileData is a model object for storing all of the POI data belonging to a single
/// vector tile. It stores POIs, roads, and intersections in separate arrays allowing for
/// simple access to the fundamentally different types of OSM data.
class TileData: Object {
    
    @objc dynamic var quadkey = ""
    
    // Array of the pois which have a super category in our super category mapping table
    let pois = List<GDASpatialDataResultEntity>()
    
    // Array of the pois which represent roads
    let roads = List<GDASpatialDataResultEntity>()
    
    // Array of the pois which represent walking paths
    let paths = List<GDASpatialDataResultEntity>()
    
    // Array of the pois which represent intersections
    let intersections = List<Intersection>()
    
    // Temporary set the etag to an empty string - eventually, we will need to actually implement an etag for checking if data has changed
    @objc dynamic var etag = ""
    
    // One week TTL for the time being
    @objc dynamic var ttl = Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)
    
    static var ttlLength: TimeInterval {
        return 7 * 24 * 60 * 60
    }
    
    private var entrances: [String: GeoJsonFeature] = [:]
    
    var tile: VectorTile {
        return VectorTile(quadKey: quadkey)
    }
    
    convenience init(withParsedData json: [String: Any], quadkey: String, etag: String, superCategories: SuperCategories) {
        self.init()
        
        // Get the vector tile info
        self.quadkey = quadkey
        
        // Update the TTL based on the `ttlLength` property
        self.ttl = Date(timeIntervalSinceNow: TileData.ttlLength)
        
        // Store the etag for checking future updates
        self.etag = etag
        
        guard let featuresJson = json["features"] as? [Any] else { return }
        
        for featureJson in featuresJson {
            // Try to parse the feature - the GeoJsonFeature initializer is failable
            guard let feature = GeoJsonFeature(json: featureJson as! [String: Any], superCategories: superCategories) else { continue }
            
            // Check if it is a road, intersection, etc.
            if feature.superCategory == .roads {
                roads.append(GDASpatialDataResultEntity(feature: feature)!)
            } else if feature.superCategory == .paths {
                paths.append(GDASpatialDataResultEntity(feature: feature)!)
                
                // Create POIs for paths which are crossings
                if feature.isCrossing {
                    if let (crossingStart, crossingEnd) = feature.decomposePathToStartAndEndCrossings() {
                        pois.append(GDASpatialDataResultEntity(feature: crossingStart, key: crossingStart.osmIds[0] + "-start")!)
                        pois.append(GDASpatialDataResultEntity(feature: crossingEnd, key: crossingStart.osmIds[0] + "-end")!)
                    }
                }
            } else if feature.superCategory == .intersections {
                intersections.append(Intersection(feature: feature))
            } else if feature.superCategory == .entranceLists {
                // Entrance lists must have at least 2 OSD IDs: the owning POI's ID and the entrance POI's ID
                if feature.osmIds.count > 1 {
                    entrances[feature.osmIds[0]] = feature
                }
            } else {
                pois.append(GDASpatialDataResultEntity(feature: feature)!)
            }
        }
        
        // Hook up entrances to their owning POIs
        for poi in pois {
            guard let entrance = entrances[poi.key] else { continue }
            
            let entsub = Array(entrance.osmIds.suffix(from: entrance.osmIds.startIndex + 1))
            do {
                let entdata = try JSONSerialization.data(withJSONObject: entsub)
                poi.entrancesJson = String(data: entdata, encoding: String.Encoding.utf8)
            } catch {
                GDLogAppError("Unable to serialize POI entrance data")
            }
        }
    }
    
    override static func ignoredProperties() -> [String] {
        return ["entrances"]
    }
    
    /// Indicates which property represents the primary key of this object
    ///
    /// - Returns: The name of the property that represents the primary key of this object
    override static func primaryKey() -> String {
        return "quadkey"
    }
    
    static func getNewExpiration() -> Date {
        return Date(timeIntervalSinceNow: TileData.ttlLength)
    }
    
    static func getExpiredTtl() -> Date {
        return Date(timeIntervalSinceNow: -1)
    }
}
