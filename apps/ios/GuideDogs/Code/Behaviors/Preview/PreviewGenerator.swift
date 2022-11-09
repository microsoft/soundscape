//
//  PreviewGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

struct PreviewGenerator<DecisionPoint: RootedPreviewGraph>: ManualGenerator {
    private var eventTypes: [UserInitiatedEvent.Type] = [
        PreviewStartedEvent<DecisionPoint>.self,
        PreviewInstructionsEvent.self,
        PreviewPausedEvent.self,
        PreviewResumedEvent<DecisionPoint>.self,
        PreviewNodeChangedEvent<DecisionPoint>.self,
        BeaconChangedEvent.self,
        PreviewBeaconUpdatedEvent.self,
        PreviewFoundRoadEvent<DecisionPoint.EdgeData>.self,
        PreviewFoundNextIntersectionEvent<DecisionPoint>.self,
        BehaviorDeactivatedEvent.self,
        PreviewMyLocationEvent<DecisionPoint>.self,
        PreviewRoadSelectionErrorEvent.self
    ]
    
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        // Generate callouts for events
        switch event {
        case let event as PreviewStartedEvent<DecisionPoint>:
            var callouts: [CalloutProtocol] = [
                GlyphCallout(.preview, .previewStart)
            ]
            callouts.append(contentsOf: event.node.makeInitialCallouts(resumed: false))

            let distance = event.node.node.location.distance(from: event.from.location)
            if distance > 1.0, !event.from.displayName.isGeocoordinate() {
                let formattedName = LanguageFormatter.string(from: distance, accuracy: 0.0, name: event.from.displayName)
                callouts.append(StringCallout(.preview, formattedName, position: event.node.node.location.bearing(to: event.from.location)))
            }
            
            let group = CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.start")
            group.onComplete = event.completionHandler
            
            // Do callouts for the initial intersection the user is starting the preview at...
            return .playCallouts(group)
            
        case let event as PreviewInstructionsEvent:
            let callouts: [CalloutProtocol] = [StringCallout(.preview, GDLocalizedString("preview.callout.road_finder.instructions"))]
            let group = CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.start")
            group.onComplete = event.completionHandler
            
            return .playCallouts(group)
            
        case is PreviewPausedEvent:
            let callouts: [CalloutProtocol] = [StringCallout(.preview, GDLocalizedString("preview.callout.paused"))]
            return .playCallouts(CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.paused"))
            
        case let event as PreviewResumedEvent<DecisionPoint>:
            let callouts: [CalloutProtocol] = event.node.makeInitialCallouts(resumed: true)
            let group = CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.start")
            group.onComplete = event.completionHandler
            
            return .playCallouts(group)
            
        case let event as PreviewNodeChangedEvent<DecisionPoint>:
            var callouts: [CalloutProtocol] = []
            
            // Do some callouts (based on whether the user is undoing their last action or moving forward) and
            // then start the wand at the new decision point...
            if event.isUndo {
                callouts.append(GlyphCallout(.preview, .travelReverse))
                callouts.append(StringCallout(.preview, GDLocalizedString("preview.callout.previous")))
            } else {
                callouts.append(GlyphCallout(.preview, .travelStart))
                
                if let previousEdgeData = event.previousEdgeData {
                    callouts.append(contentsOf: event.edgeData.makeCalloutsForSelectedEvent(from: previousEdgeData))
                }
                
                if event.edgeData.adjacent.count > 0 {
                    callouts.append(contentsOf: event.edgeData.makeCalloutsForAdjacents())
                }
                
                callouts.append(contentsOf: event.to.makeCallouts(previous: event.from))
            }
            
            let group = CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.node_changed.\(event.isUndo ? "previous" : "next")")
            group.onComplete = event.completionHandler
            
            return .playCallouts(group)
            
        case let event as BeaconChangedEvent:
            guard let key = event.markerId else {
                return nil
            }
            
            return .playCallouts(CalloutGroup([DestinationCallout(.preview, key)], action: .interruptAndClear, logContext: "preview.beacon_set"))
            
        case let event as PreviewBeaconUpdatedEvent:
            var callouts: [CalloutProtocol] = []
            
            if event.arrived {
                let formattedDistance = LanguageFormatter.formattedDistance(from: DestinationManager.EnterImmediateVicinityDistance)
                
                callouts.append(GenericCallout(.preview, description: "arrived at beacon (in preview)") { (_, _, _) -> [Sound] in
                    let earcon = GlyphSound(.beaconFound)
                    let tts = TTSSound(GDLocalizedString("beacon.beacon_location_within_audio_beacon_muted", formattedDistance), at: event.location)
                    
                    guard let layered = LayeredSound(earcon, tts) else {
                        return [earcon, tts]
                    }
                    
                    return [layered]
                })
            } else {
                let formattedDistance = LanguageFormatter.string(from: event.distance, accuracy: 0.0, name: GDLocalizedString("beacon.generic_name"))
                
                callouts.append(GenericCallout(.preview, description: "beacon update (in preview)") { (_, _, _) -> [Sound] in
                    let earcon = GlyphSound(SuperCategory.places.glyph, at: event.location)
                    let tts = TTSSound(formattedDistance, at: event.location)
                    
                    guard let layered = LayeredSound(earcon, tts) else {
                        return [earcon, tts]
                    }
                    
                    return [layered]
                })
            }
            
            let group = CalloutGroup(callouts, action: .interruptAndClear, logContext: "Preview beacon update (arrived: \(event.arrived))")
            group.onComplete = event.completionHandler
            
            return .playCallouts(group)
            
        case let event as PreviewFoundRoadEvent<DecisionPoint.EdgeData>:
            // Callout the name of the road that is highlighted
            let callouts = CalloutGroup(event.edgeData.makeCalloutsForFocusEvent(), action: .interruptAndClear, logContext: "preview.road_focussed")
            callouts.onComplete = event.completionHandler
            return .playCallouts(callouts)
            
        case let event as PreviewFoundNextIntersectionEvent<DecisionPoint>:
            return .playCallouts(CalloutGroup(event.edgeData.makeCalloutsForLongFocusEvent(from: event.from.node), action: .interruptAndClear, logContext: "preview.road_long_focussed"))
            
        case let event as BehaviorDeactivatedEvent:
            let callouts = [GenericCallout(.preview, description: "preview ended") { (_, _, _) -> [Sound] in
                let earcon = GlyphSound(.previewEnd)
                let tts = TTSSound(GDLocalizedString("preview.callout.end"))
                
                guard let layered = LayeredSound(earcon, tts) else {
                    return [earcon, tts]
                }
                
                return [layered]
            }]
            
            // Play the sound that caps off the end of the preview mode
            let group = CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.end")
            group.onComplete = event.completionHandler
            
            return .playCallouts(group)
            
        case let event as PreviewMyLocationEvent<DecisionPoint>:
            let callout = StringCallout(.preview, GDLocalizedString("directions.at_poi", event.current.node.localizedName), position: 0.0)
            let group = CalloutGroup([callout], action: .interruptAndClear, playModeSounds: true, logContext: "preview.my_location")
            group.onComplete = event.completionHandler
            
            return .playCallouts(group)
            
        case is PreviewRoadSelectionErrorEvent:
            guard !FirstUseExperience.didComplete(.previewRoadFinderError) else {
                return .playCallouts(CalloutGroup([GlyphCallout(.preview, .roadFinderError)], action: .interruptAndClear, logContext: "preview.road_selection_error"))
            }
            
            FirstUseExperience.setDidComplete(for: .previewRoadFinderError)
            
            let callouts: [CalloutProtocol] = [
                GlyphCallout(.preview, .roadFinderError),
                StringCallout(.preview, GDLocalizedString("preview.callout.road_finder.error_instructions"))
            ]
            
            return .playCallouts(CalloutGroup(callouts, action: .interruptAndClear, logContext: "preview.road_selection_error"))
            
        default:
            // Intentional no-op. We should never receive events other than those above...
            return nil
        }
    }
    
}
