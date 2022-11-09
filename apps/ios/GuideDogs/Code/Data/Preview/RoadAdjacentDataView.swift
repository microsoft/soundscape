//
//  RoadAdjacentDataView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import CocoaLumberjackSwift
import iOS_GPX_Framework

struct RoadAdjacentDataView: AdjacentDataView, Equatable {
    
    typealias ReferenceEntityID = String

    /// Used to check if an adjacent has been called out within this threshold
    private static var adjacentCalloutThreshold: CLLocationDistance = CLLocationDistance.averageWalkingSpeed * 30 // 42 meters
    
    // MARK: Properties
    
    let endpoint: Intersection
    let direction: RoadDirection
    let coordinatesToEndpoint: [CLLocationCoordinate2D]
    let style: Intersection.Style
    
    /// All valid markers that can be called out along the path to the endpoint
    let adjacent: [ReferenceEntityID]
    
    /// All valid markers and all previous markers that have been called out
    /// leading up to this path, that are still within a valid range.
    let adjacentCalloutLocationsHistory: [ReferenceEntityID: CLLocationCoordinate2D]
    
    // MARK: Computed Properties
    
    /// Indicates if this edge is an edge that the Street Preview supports moving along (e.g. is it a road
    /// rather than a walking path or cycleway).
    var isSupported: Bool {
        // Both checks below must pass to be considered a main edge. For example:
        //   1. a named walking path will always return `false`;
        //   2. if `SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads` is set to `.standard`, an unnamed service road will return `true`;
        //   3. if it is set to `.strict`, an unnamed service road will return `false`
        
        // Walking paths, cycleways, stairs, etc. are never main edges regardless of whether they are
        // named or not (Note: this intentionally uses .standard rather than the current value of
        // `SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads` since we are only concerned
        // with paths that aren't roads for this first check
        guard direction.road.isMainRoad(context: .standard, detectionType: .roadType) else {
            return false
        }
        
        // Check if we consider this edge a main road by name
        let secondaryRoadsContext: SecondaryRoadsContext = SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads ? .standard : .strict
        return direction.road.isMainRoad(context: secondaryRoadsContext, detectionType: .roadName)
    }
    
    // MARK: Initialization
    
    private init(intersectionSearchResult result: IntersectionSearchResult, from: RoadAdjacentDataView? = nil) {
        endpoint = result.intersection
        direction = RoadDirection(result.road, result.bearing, Direction(from: result.bearing))
        coordinatesToEndpoint = result.coordinatesToIntersection
        style = result.style
        
        // Transform the OSM road coordinates to walking path coordinates
        let walkingPathToIntersection = GeometryUtils.interpolateToEqualDistance(coordinates: result.coordinatesToIntersection,
                                                                                 distance: CLLocationDistance.averageWalkingSpeed)
        
        // Calculate the valid markers
        let validMarkersAlongPath = RoadAdjacentDataView.validMarkersAlongPath(walkingPathToIntersection, from: from)
        adjacent = validMarkersAlongPath.map { $0.id }
        
        // Process the updated markers history
        adjacentCalloutLocationsHistory = RoadAdjacentDataView.updatedMarkerHistory(newMarkers: validMarkersAlongPath,
                                                                                    targetLocation: endpoint.coordinate,
                                                                                    from: from)
    }
    
    /// Builds the decision point corresponding to the endpoint along this edge in the
    /// road graph.
    ///
    /// - Returns: Decision point corresponding to `endpoint`
    func decisionPointForEndpoint() -> IntersectionDecisionPoint {
        return IntersectionDecisionPoint(node: endpoint, style: style, from: self)
    }
    
    // MARK: Callout Generation
    
    /// Generates the callouts which occur for markers adjacent to this edge in the road
    /// graph when the user is navigating along this edge to the next decision point.
    ///
    /// - Returns: Array of callouts for adjacent markers
    func makeCalloutsForAdjacents() -> [CalloutProtocol] {
        let markers = adjacent.compactMap { SpatialDataCache.referenceEntityByKey($0) }
        
        return markers.enumerated().flatMap { (item) -> [CalloutProtocol] in
            let position = direction.bearing
            let category = SuperCategory(rawValue: item.element.getPOI().superCategory) ?? .undefined
            let name = item.element.name
            
            if item.offset == 0 {
                return [
                    GlyphCallout(.preview, category.glyph, position: position),
                    StringCallout(.preview, name, position: position)
                ]
            } else {
                return [
                    GenericCallout(.preview, description: "adjacent marker") { (_, _, _) in
                        let markerGlyph = GlyphSound(category.glyph, compass: position)
                        let markerTTS = TTSSound(name, compass: position)
                        
                        guard let ttsSound = ConcatenatedSound(markerGlyph, markerTTS),
                            let layered = LayeredSound(ttsSound, GlyphSound(.travelInter, compass: position)) else {
                            return []
                        }
                        
                        return [layered]
                    }
                ]
            }
        }
    }
    
    /// Generates the callouts which occur when the user points their phone at this edge
    /// while deciding on which road to move along at a decision point.
    ///
    /// - Returns: An array of callouts for the focus event
    func makeCalloutsForFocusEvent() -> [CalloutProtocol] {
        let name = direction.road.localizedName
        let bearing = direction.bearing
        let asset: StaticAudioEngineAsset = isSupported ? .streetFound : .roadFinderError
        
        if let compass = CardinalDirection(direction: direction.bearing) {
            return [GenericCallout(.preview, description: "street found") { (_, _, _) in
                let glyph = GlyphSound(asset, compass: bearing)
                let name = TTSSound(GDLocalizedString("preview.callout.road_finder.road", name, compass.localizedString), compass: bearing)
                
                guard let layers = LayeredSound(glyph, name) else {
                    return []
                }
                
                return [layers]
            }]
        }
        
        return [GenericCallout(.preview, description: "street found") { (_, _, _) in
            let glyph = GlyphSound(asset, compass: bearing)
            let name = TTSSound(name, compass: bearing)
            
            guard let layers = LayeredSound(glyph, name) else {
                return []
            }
            
            return [layers]
        }]
    }
    
    func makeCalloutsForLongFocusEvent(from: Intersection) -> [CalloutProtocol] {
        let bearing = direction.bearing
        
        if from.key == endpoint.key {
            // If the next intersection is the same as the current intersection, then the road loops around...
            return [GenericCallout(.preview, description: "street found - returns to current intersection") { (_, _, _) in
                let glyph = GlyphSound(.streetFound, compass: bearing)
                let name = TTSSound(GDLocalizedString("preview.callout.road_finder.intersection.same"), compass: bearing)
                
                guard let layers = LayeredSound(glyph, name) else {
                    return []
                }
                
                return [layers]
            }]
        }

        let distance = endpoint.location.distance(from: from.location)
        let formattedDistance = LanguageFormatter.formattedDistance(from: distance)
        let distanceCallout = StringCallout(.preview, formattedDistance, position: bearing)
        
        if style == .roadEnd {
            let roadEndCallout = GenericCallout(.preview, description: "street found") { (_, _, _) in
                let glyph = GlyphSound(.streetFound, compass: bearing)
                let name = TTSSound(GDLocalizedString("preview.callout.road_finder.intersection.end"), compass: bearing)
                
                guard let layers = LayeredSound(glyph, name) else {
                    return []
                }
                
                return [layers]
            }
            
            return [roadEndCallout, distanceCallout]
        } else {
            let name = endpoint.localizedName
            let intersectionCallout = GenericCallout(.preview, description: "street found") { (_, _, _) in
                let glyph = GlyphSound(.streetFound, compass: bearing)
                let name = TTSSound(GDLocalizedString("preview.callout.road_finder.intersection", name), compass: bearing)
                
                guard let layers = LayeredSound(glyph, name) else {
                    return []
                }
                
                return [layers]
            }
            
            return [intersectionCallout, distanceCallout]
        }
    }
    
    func makeCalloutsForSelectedEvent(from previousEdgeData: RoadAdjacentDataView) -> [CalloutProtocol] {
        // If we are leaving a roundabout, make that clear
        if previousEdgeData.style == .roundabout && self.style != .roundabout {
            return [StringCallout(.preview, GDLocalizedString("preview.callout.turn.roundabout", self.direction.road.localizedName))]
        }
        
        // Calculate the bearing between the user's previously selected edge
        // and the newly selected edge
        // This will indicate whether the user is turning right or left
        let bearing = previousEdgeData.direction.bearing.bearing(to: direction.bearing)
        let direction = Direction(from: bearing)
        
        switch direction {
        case .left, .aheadLeft, .behindLeft:
            return [StringCallout(.preview, GDLocalizedString("preview.callout.turn.left", self.direction.road.localizedName))]
        case .right, .aheadRight, .behindRight:
            return [StringCallout(.preview, GDLocalizedString("preview.callout.turn.right", self.direction.road.localizedName))]
        case .ahead:
            return [StringCallout(.preview, GDLocalizedString("preview.callout.turn.continue", self.direction.road.localizedName))]
        default:
            return []
        }
    }
}

// MARK: Static Initialization Methods

extension RoadAdjacentDataView {
    
    /// Returns the adjacent intersections to a given root intersections.
    ///
    /// - Parameters:
    ///   - intersection: The root intersection to search from.
    /// - Returns: The adjacent intersections to a given root intersections, as `RoadAdjacentDataView` objects.
    static func make(for root: Intersection, from: RoadAdjacentDataView? = nil) -> [RoadAdjacentDataView] {
        var adjacent: [RoadAdjacentDataView] = []
        
        for road in root.distinctRoads {
            let adjacentIntersections = RoadAdjacentDataView.adjacentIntersections(at: root, onRoad: road, from: from)
            
            for adjacentIntersection in adjacentIntersections {
                // In some cases, multiple roads leaving an intersection can intersect again along the roads.
                // For example, the intersections of Northeast 38th Street and Northeast 39th Street, Redmond, WA, USA.
                // https://www.openstreetmap.org/node/53121426
                // https://www.openstreetmap.org/node/53121437
                //
                //         A
                //  →  /‾‾‾‾‾‾‾‾\
                // ---+          +---
                //     \________/
                //         B
                //
                
                // Make sure we don't include an intersection we already included unless the direction to get to that
                // intersection is different (e.g. you are standing in a roundabout and can go either way around the
                // roundabout to get to the same intersection)
                guard !adjacent.contains(where: { $0.endpoint == adjacentIntersection.endpoint && $0.direction.bearing == adjacentIntersection.direction.bearing }) else {
                    continue
                }
                
                adjacent.append(adjacentIntersection)
            }
        }
        
        return adjacent
    }
    
    /// Returns the adjacent intersections (leading and/or trailing) to a given root intersections, on a specific road.
    ///
    /// - Parameters:
    ///   - intersection: The root intersection to search from.
    ///   - road: The road to search on.
    /// - Returns: The adjacent intersections to a given root intersections, as `RoadAdjacentDataView` objects.
    private static func adjacentIntersections(at intersection: Intersection,
                                              onRoad road: Road,
                                              from: RoadAdjacentDataView? = nil) -> [RoadAdjacentDataView] {
        let secondaryRoadsContext: SecondaryRoadsContext = SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads ? .standard : .strict
        
        guard let intersectionFinder = IntersectionFinder(rootCoordinate: intersection.coordinate,
                                                          road: road,
                                                          preferMainIntersections: true,
                                                          secondaryRoadsContext: secondaryRoadsContext) else { return [] }
        
        let closestIntersections = intersectionFinder.closestIntersections()
        
        var adjacentDataViews: [RoadAdjacentDataView] = []
        
        if let leading = closestIntersections.leading {
            let adjacentDataView = RoadAdjacentDataView(intersectionSearchResult: leading, from: from)
            adjacentDataViews.append(adjacentDataView)
        }
        
        if let trailing = closestIntersections.trailing {
            let adjacentDataView = RoadAdjacentDataView(intersectionSearchResult: trailing, from: from)
            adjacentDataViews.append(adjacentDataView)
        }
        
        return adjacentDataViews
    }
    
    /// Returns the markers that can be called out whaile walking along a path
    private static func markersAlongPath(_ coordinates: [CLLocationCoordinate2D]) -> [ReferenceEntity] {
        var markers: [ReferenceEntity] = []
        
        let updateFilter = LocationUpdateFilter(minTime: 0.0, minDistance: 5.0)
        
        for coordinate in coordinates {
            let location = CLLocation(coordinate)
            
            guard updateFilter.shouldUpdate(location: location) else {
                continue
            }
            
            let markersAtCoordinate = SpatialDataCache.referenceEntitiesNear(coordinate, range: CalloutRangeContext.streetPreview.searchDistance)
            
            for marker in markersAtCoordinate {
                guard !markers.contains(where: { $0.id == marker.id }) else {
                    // Discard duplicate markers
                    continue
                }
                
                let distance = marker.distanceToClosestLocation(from: location)
                let category = SuperCategory(rawValue: marker.getPOI().superCategory) ?? SuperCategory.undefined
                let triggerRange = category.triggerRange(context: .streetPreview)
                
                // Only allow markers within the trigger range
                guard distance <= triggerRange else {
                    continue
                }
                
                markers.append(marker)
            }
            
        }
        
        return markers
    }
    
    /// Returns the valid markers that can be called out along a path.
    /// This takes into account the marker callout history from previous roads (if given).
    private static func validMarkersAlongPath(_ coordinates: [CLLocationCoordinate2D],
                                              from: RoadAdjacentDataView? = nil) -> [ReferenceEntity] {
        let allMarkers = RoadAdjacentDataView.markersAlongPath(coordinates)
        
        guard !allMarkers.isEmpty else {
            return []
        }
        
        // If no history given, all found markers are valid.
        guard let from = from else {
            return allMarkers
        }
            
        var validMarkers: [ReferenceEntity] = []
        
        // The previous endpoint location (which is the current origin position)
        let endpointLocation = from.endpoint.coordinate
        
        for marker in allMarkers {
            // We only allow a marker callout if it was not called out within a distance threshold.
            // I.e. we don't want repeated callouts for the same marker in close proximity.
            
            if let prevCalloutLocation = from.adjacentCalloutLocationsHistory[marker.id] {
                guard endpointLocation.distance(from: prevCalloutLocation) > RoadAdjacentDataView.adjacentCalloutThreshold else {
                    // The adjacent is within the threshold, i.e. not valid.
                    continue
                }
            }
            
            validMarkers.append(marker)
        }
        
        return validMarkers
    }
    
    /// Returns a marker callout history based on new found markers and marker callout history.
    private static func updatedMarkerHistory(newMarkers: [ReferenceEntity],
                                             targetLocation: CLLocationCoordinate2D,
                                             from: RoadAdjacentDataView? = nil) -> [ReferenceEntityID: CLLocationCoordinate2D] {
        var updatedHistory: [ReferenceEntityID: CLLocationCoordinate2D] = [:]
        
        // Add marker from previous history if needed
        if let from = from {
            // The previous endpoint location (which is the current origin position)
            let endpointLocation = from.endpoint.coordinate
            
            // Only add markers that are still in proximity to current history
            for (markerId, coordinate) in from.adjacentCalloutLocationsHistory {
                guard coordinate.distance(from: endpointLocation) < RoadAdjacentDataView.adjacentCalloutThreshold else {
                    // The adjacent is outside the threshold, i.e., expired.
                    continue
                }
                
                updatedHistory[markerId] = coordinate
            }
        }
        
        // Add new markers
        for marker in newMarkers {
            updatedHistory[marker.id] = targetLocation
        }
        
        return updatedHistory
    }
    
}
