//
//  IntersectionDecisionPoint.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct IntersectionDecisionPoint: RootedPreviewGraph {
    
    // MARK: Properties
    
    let node: Intersection
    let edges: [RoadAdjacentDataView]
    
    private let from: RoadAdjacentDataView?
    private let style: Intersection.Style
    
    // MARK: Initialization
    
    init(node: Intersection) {
        self.init(node: node, style: .standard)
    }
    
    init(node: Intersection, style: Intersection.Style, from: RoadAdjacentDataView? = nil) {
        self.node = node
        self.style = style
        self.edges = RoadAdjacentDataView.make(for: node, from: from)
        self.from = from
    }
    
    /// Generates the callouts which should be played if this decision point
    /// is the user's starting location in the location preview experience.
    ///
    /// - Returns: An array of callouts for starting the location preview experience
    func makeInitialCallouts(resumed: Bool = false) -> [CalloutProtocol] {
        let name = node.localizedName()
        
        if resumed {
            if style == .standard {
                return [StringCallout(.preview, GDLocalizedString("preview.callout.continue.at", name))]
            }
            
            return [StringCallout(.preview, GDLocalizedString("preview.callout.continue.along", name))]
        }
        
        if style == .standard {
            return [StringCallout(.preview, GDLocalizedString("preview.callout.start.at", name))]
        }
        
        return [StringCallout(.preview, GDLocalizedString("preview.callout.start.along", name))]
    }
    
    /// Generates the callouts which should be played when the user arrives at this
    /// decision point after navigating away from a previous decision point
    ///
    /// - Parameter previous: The previous decision point the user was at
    ///
    /// - Returns: An array of callouts describing this decision point
    func makeCallouts(previous: IntersectionDecisionPoint) -> [CalloutProtocol] {
        GDLogPreviewInfo("Making callouts for intersection...")
        
        // Get the inverse direction (heading into the intersection rather than out of it)
        let direction = findApproachBearing(from: previous)
        
        // Build the sounds for the constituent roads ("A goes left", "B continues ahead", "C goes right", etc.)
        let roads = IntersectionCallout.directionSounds(intersection: node,
                                                        relativeTo: direction,
                                                        roundabout: style == .roundabout)
        
        let approach: String
        switch style {
        case .standard:
            approach = GDLocalizedString("intersection.approaching_intersection")
        case .roundabout:
            if previous.style != .roundabout {
                approach = GDLocalizedString("directions.approaching_roundabout")
            } else {
                // If we are already in the roundabout, there is no need to continue saying that we are approaching it
                approach = GDLocalizedString("intersection.approaching_intersection")
            }
        case .roadEnd:
            approach = GDLocalizedString("preview.callout.approach.end")
        case .circleDrive:
            if previous.node.roads.contains(where: { GeometryUtils.pathIsCircular($0.coordinates ?? []) }) {
                // When exiting a circle drive, just say you are approaching an intersection because you are already on the roundabout
                approach = GDLocalizedString("intersection.approaching_intersection")
            } else {
                // When entering a circle drive, say that it is a roundabout
                approach = GDLocalizedString("directions.approaching_roundabout")
            }
        }
        
        GDLogPreviewInfo("Approaching with: \"\(approach)\"")
        
        return [GenericCallout(.preview, description: "approaching intersection") { (_, _, _) in
            let earcon = GlyphSound(.poiSense, compass: direction)
            let tts = TTSSound(approach, compass: direction)
            
            guard let ttsSound = ConcatenatedSound(earcon, tts), let layered = LayeredSound(ttsSound, GlyphSound(.travelEnd, compass: direction)) else {
                GDLogPreviewError("Unable to concatenate and layer sounds...")
                return []
            }
            
            guard let roads = roads, !roads.isEmpty else {
                GDLogPreviewError("No road sounds were available for the intersection callout")
                return [layered]
            }
            
            return [layered] + roads
        }]
    }
    
    /// Finds the bearing the user approached this intersection from (or an approximation thereof).
    ///
    /// - Parameter from: The previous decision point the user was at before moving to this decision point.
    /// - Returns: The bearing the user approached along
    private func findApproachBearing(from: IntersectionDecisionPoint) -> CLLocationDirection {
        // Find the edge that goes back towards the node the user came from
        guard let edge = edges.first(where: { $0.endpoint == from.node }) else {
            // We should always be able to find the edge, but if we can't we should default
            // to using the bearing between the two intersections. This won't work perfectly roads
            // with complex geometries between intersections, but it should be an acceptable
            // substitute in the majority of cases...
            GDLogPreviewError("Couldn't find the edge the user approached on! Using bearing between intersections...")
            return from.node.location.bearing(to: node.location)
        }
        
        // The direction of this edge is leaving the intersection, so invert it to get the direction entering the intersection
        return edge.direction.bearing.add(degrees: 180.0)
    }
    
    func refreshed() -> IntersectionDecisionPoint {
        return IntersectionDecisionPoint(node: node, style: style, from: from)
    }
    
}
