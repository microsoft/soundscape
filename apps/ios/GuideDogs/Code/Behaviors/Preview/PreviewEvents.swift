//
//  PreviewEvents.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

class PreviewStartedEvent<DecisionPoint: RootedPreviewGraph>: UserInitiatedEvent {
    let node: DecisionPoint
    let from: LocationDetail
    
    let completionHandler: ((Bool) -> Void)?
    
    init(at: DecisionPoint, from: LocationDetail, completionHandler: ((Bool) -> Void)? = nil) {
        node = at
        self.from = from
        self.completionHandler = completionHandler
    }
}

class PreviewInstructionsEvent: UserInitiatedEvent {
    var completionHandler: ((Bool) -> Void)?
    
    init(completionHandler: ((Bool) -> Void)? = nil) {
        self.completionHandler = completionHandler
    }
}

class PreviewPausedEvent: UserInitiatedEvent { }

class PreviewResumedEvent<DecisionPoint: RootedPreviewGraph>: UserInitiatedEvent {
    var node: DecisionPoint
    
    var completionHandler: ((Bool) -> Void)?
    
    init(at: DecisionPoint, completionHandler: ((Bool) -> Void)? = nil) {
        node = at
        self.completionHandler = completionHandler
    }
}

class PreviewFoundRoadEvent<EdgeData: AdjacentDataView>: UserInitiatedEvent {
    var edgeData: EdgeData
    
    var completionHandler: ((Bool) -> Void)?
    
    init(_ data: EdgeData, completionHandler: ((Bool) -> Void)? = nil) {
        self.edgeData = data
        self.completionHandler = completionHandler
    }
}

class PreviewFoundNextIntersectionEvent<DecisionPoint: RootedPreviewGraph>: UserInitiatedEvent {
    var from: DecisionPoint
    var edgeData: DecisionPoint.EdgeData
    
    init(from: DecisionPoint, along data: DecisionPoint.EdgeData) {
        self.from = from
        self.edgeData = data
    }
}

class PreviewNodeChangedEvent<DecisionPoint: RootedPreviewGraph>: UserInitiatedEvent {
    var from: DecisionPoint
    var to: DecisionPoint
    var edgeData: DecisionPoint.EdgeData
    var isUndo: Bool
    var previousEdgeData: DecisionPoint.EdgeData?
    
    var completionHandler: ((Bool) -> Void)?
    
    init(from: DecisionPoint, to: DecisionPoint, along: DecisionPoint.EdgeData, previousEdgeData: DecisionPoint.EdgeData?, isUndo undo: Bool = false, completionHandler: ((Bool) -> Void)? = nil) {
        self.from = from
        self.to = to
        edgeData = along
        self.previousEdgeData = previousEdgeData
        isUndo = undo
        self.completionHandler = completionHandler
    }
}

class PreviewBeaconUpdatedEvent: UserInitiatedEvent {
    let distance: CLLocationDistance
    let location: CLLocation
    let arrived: Bool
    
    var completionHandler: ((Bool) -> Void)?
    
    init(location: CLLocation, distance: CLLocationDistance, arrived: Bool, completionHandler: ((Bool) -> Void)? = nil) {
        self.location = location
        self.distance = distance
        self.arrived = arrived
        self.completionHandler = completionHandler
    }
}

class PreviewMyLocationEvent<DecisionPoint: RootedPreviewGraph>: UserInitiatedEvent {
    var current: DecisionPoint
    var completionHandler: ((Bool) -> Void)?
    
    init(current: DecisionPoint, completionHandler: ((Bool) -> Void)? = nil) {
        self.current = current
        self.completionHandler = completionHandler
    }
}

class PreviewRoadSelectionErrorEvent: UserInitiatedEvent { }
