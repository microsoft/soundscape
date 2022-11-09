//
//  PreviewBehavior.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

typealias StreetPreviewBehavior = PreviewBehavior<IntersectionDecisionPoint>

struct Decision<DecisionPoint: RootedPreviewGraph> {
    let decisionPoint: DecisionPoint
    let selectedEdgeIndex: Array<DecisionPoint.EdgeData>.Index
    
    var selectedEdge: DecisionPoint.EdgeData {
        return decisionPoint.edges[selectedEdgeIndex]
    }
}

class PreviewBehavior<DecisionPoint: RootedPreviewGraph>: BehaviorBase {
    
    // MARK: Properties
    
    /// Current value subject which publishes a boolean indicating whether the `PreviewStartEvent`
    /// has completed
    private(set) var isStartedSubject: CurrentValueSubject<Bool, Never>
    
    /// Current value subject which publishes a boolean indicating whether a transition between
    /// decision points is in progress
    private(set) var isTransitioningSubject: CurrentValueSubject<Bool, Never>
    
    /// A current value subject which publishes the current decision point as it changes
    private(set) var currentDecisionPoint: CurrentValueSubject<DecisionPoint, Never>
    
    /// A current value subject which publishes the currently selected edge in the road
    /// graph. When the user is "moving" along an edge (hearing callouts for the edge after
    /// having selected it), this will hold a reference to that edge. When the user is at
    /// a decision point and is using the physical wand UI to learn about the available edges
    /// which can be traversed, this will be equal to the last edge hovered over (or nil if an
    /// edge hasn't been hovered over yet).
    private(set) var currentlyFocussedRoad: CurrentValueSubject<DecisionPoint.EdgeData?, Never>
    
    private var mostRecentFocussedRoad: DecisionPoint.EdgeData?
    
    private var didCalloutFocussedTarget: Bool = false
    
    /// History of previous decisions with the latest decision at the end of the array.
    private var previous: [Decision<DecisionPoint>] = []
    
    /// Flag indicating if the preview behavior has previous decisions it can revert or not
    public var canGoToPrevious: Bool {
        return !previous.isEmpty
    }
    
    /// Haptic engine for rendering haptics for the physical UI at decision points
    private let engine = HapticEngine()
    
    /// Wand for tracking when the user is pointing their phone at roads they
    /// can travel down in the preview so that haptics corresponding to available
    /// road directions can be triggered appropriately
    private let roadWand = PreviewWand()
    
    private let roadWindow = 60.0
    
    /// ID for the beacon that plays ambient audio when the wand isn't pointed at a road
    private var roadWandBeacon: AudioPlayerIdentifier?
    
    /// Haptic style triggered for available road direction feedback
    private let roadFeedbackStyle: HapticEngine.FeedbackStyle = .impactHeavy
    
    /// Wand for tracking when the user is pointing their phone at 30 degree increments
    /// so that haptics corresponding to the compass can be triggered appropriately. This
    /// recreates the same haptic experience as in the Compass app
    private let compassWand = PreviewWand()
    
    /// Haptic style to trigger for compass feedback
    private let compassFeedbackStyle: HapticEngine.FeedbackStyle = .impactLight
    
    /// Private implementation of an orientable for building the compass feedback
    private struct CompassOrientation: Orientable {
        let bearing: CLLocationDirection
    }
    
    // MARK: App State Cancellables
    
    private var cancellationTokens: [AnyCancellable] = []
    
    // MARK: Location and Course Delegate
    
    unowned let geolocationManager: GeolocationManagerProtocol
    
    weak var locationDelegate: LocationProviderDelegate?
    
    weak var courseDelegate: CourseProviderDelegate?
    
    // MARK: Initialization Info
    
    let initialLocation: LocationDetail
    
    // MARK: Beacon
    
    unowned let destinationManager: DestinationManagerProtocol
    
    /// Key for looking up the beacon (if one is set)
    private var beaconKey: String?
    
    private var didPauseBeaconOnPause: Bool = false
    
    // MARK: Initialization
    
    /// Initializes the preview experience at the provided decision point and sets the current
    /// decision (currently selected edge in the road graph) to nil.
    ///
    /// - Parameter initial: The decision point to start the preview at
    init(at initial: DecisionPoint, from: LocationDetail, geolocationManager: GeolocationManagerProtocol, destinationManager: DestinationManagerProtocol) {
        self.isStartedSubject = .init(false)
        self.currentDecisionPoint = .init(initial)
        self.currentlyFocussedRoad = .init(nil)
        self.isTransitioningSubject = .init(false)
        self.geolocationManager = geolocationManager
        self.destinationManager = destinationManager
        self.initialLocation = from
        
        super.init(blockedAutoGenerators: [AutoCalloutGenerator.self, BeaconCalloutGenerator.self], blockedManualGenerators: [BeaconCalloutGenerator.self])
        
        // Configure the wands
        roadWand.delegate = self
        compassWand.delegate = self
    }
    
    override func activate(with parent: Behavior?) {
        super.activate(with: parent)
        
        // Register any preview mode generators here
        manualGenerators.append(PreviewGenerator<DecisionPoint>())
        
        // If there is a beacon set, mute it
        if destinationManager.isAudioEnabled {
            destinationManager.toggleDestinationAudio(true)
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        geolocationManager.add(self as LocationProvider)
        geolocationManager.add(self as CourseProvider)
        
        locationDelegate?.locationProvider(self, didUpdateLocation: currentDecisionPoint.value.node.location)
        courseDelegate?.courseProvider(self, didUpdateCourse: nil)
        
        engine.setup(for: [roadFeedbackStyle, compassFeedbackStyle])
        GDATelemetry.track("preview.start")
        
        cancellationTokens.append(NotificationCenter.default.publisher(for: .appDidBecomeActive).sink { [weak self] _ in
            self?.resumePreview()
        })
        
        cancellationTokens.append(NotificationCenter.default.publisher(for: .appDidEnterBackground).sink { [weak self] _ in
            self?.pausePreview()
        })
        
        cancellationTokens.append(NotificationCenter.default.publisher(for: .destinationChanged, object: AppContext.shared.spatialDataContext.destinationManager).sink { [weak self] (notification) in
            guard let `self` = self else {
                return
            }
            
            guard let key = notification.userInfo?[DestinationManager.Keys.destinationKey] as? String else {
                self.beaconKey = nil
                return
            }
            
            self.beaconKey = key
        })
        
        cancellationTokens.append(NotificationCenter.default.publisher(for: .previewIntersectionsIncludeUnnamedRoadsDidChange).sink(receiveValue: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            self.stopWands()
            
            self.currentlyFocussedRoad.value = nil
            self.currentDecisionPoint.value = self.currentDecisionPoint.value.refreshed()
            
            self.startWands()
        }))
        
        cancellationTokens.append(NotificationCenter.default.publisher(for: .audioEngineStateChanged).sink(receiveValue: { [weak self] (notification) in
            guard let `self` = self else {
                return
            }
            
            guard let userInfo = notification.userInfo,
                  let stateValue = userInfo[AudioEngine.Keys.audioEngineStateKey] as? Int,
                  let state = AudioEngine.State(rawValue: stateValue) else {
                    return
            }
            
            guard self.isStartedSubject.value else {
                // If the preview has not started, there is nothing to do
                return
            }
            
            if state == .stopped {
                self.stopWands()
            } else if state == .started {
                self.startWands()
            }
        }))
        
        delegate?.process(PreviewStartedEvent(at: currentDecisionPoint.value, from: initialLocation) { [weak self] _ in
            guard let `self` = self, !self.isDeactivating else {
                return
            }
            
            if !FirstUseExperience.didComplete(.previewRoadFinder) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
                    self?.delegate?.process(PreviewInstructionsEvent { _ in
                        self?.didActivate()
                    })
                }
            } else {
                self.didActivate()
            }
        })
    }
    
    private func didActivate() {
        DispatchQueue.main.async { [weak self] in
            self?.isStartedSubject.value = true
            self?.startWands()
        }
    }
    
    override func willDeactivate() {
        super.willDeactivate()
        
        // If there is a beacon set, mute it
        if destinationManager.isAudioEnabled {
            destinationManager.toggleDestinationAudio(true)
        }
        
        stopWands()
    }
    
    override func deactivate() -> Behavior? {
        GDATelemetry.track("preview.stop")
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        isStartedSubject.value = false
        mostRecentFocussedRoad = nil
        
        // Stop listening to foreground/background notifications
        cancellationTokens.forEach { $0.cancel() }
        cancellationTokens.removeAll()
        
        // Remove self as the current location and course provider
        geolocationManager.remove(self as LocationProvider)
        geolocationManager.remove(self as CourseProvider)
        
        // Stop the haptics
        engine.teardownAll()
        
        return super.deactivate()
    }
    
    // MARK: Preview
    
    /// Check if the provided edge is the same as the edge moved along in the previous decision.
    ///
    /// - Parameter edge: The edge to check against the previous decision
    ///
    /// - Returns: True if this is the same edge the user last moved along in the preview. False otherwise.
    func isPrevious(edge: DecisionPoint.EdgeData) -> Bool {
        guard let last = previous.last else {
            return false
        }
        
        return edge.endpoint == last.decisionPoint.node
    }
    
    /// Moves the user along the provided edge, sends a PreviewNodeChangedEvent to generate
    /// callouts, and then updates the current decision point.
    ///
    /// - Parameter edge: The edge to move along. If nil, this will trigger an error callout to be generated
    ///                   signalling to the user that they cannot travel along a non-existent road
    func select(_ edge: DecisionPoint.EdgeData?) {
        guard let edge = edge else {
            if !isTransitioningSubject.value {
                delegate?.process(PreviewRoadSelectionErrorEvent())
            }
            return
        }
        
        let current = currentDecisionPoint.value
        
        // We should only move along valid edges from our current decision point...
        guard let index = current.edges.firstIndex(where: { $0.endpoint == edge.endpoint }) else {
            return
        }
        
        GDATelemetry.track("preview.select")
        
        isTransitioningSubject.value = true
        
        // Get the new decision point we are going to move to, and reset the current decision
        let next = edge.decisionPointForEndpoint()
        
        currentlyFocussedRoad.value = nil
        
        stopWands()
        
        // Update the history and the current decision point
        previous.append(Decision(decisionPoint: current, selectedEdgeIndex: index))
        currentDecisionPoint.value = next
        
        locationDelegate?.locationProvider(self, didUpdateLocation: next.node.location)
        
        // If this is the first time the user has selected a road, remember that they did it
        if !FirstUseExperience.didComplete(.previewRoadFinder) {
            FirstUseExperience.setDidComplete(for: .previewRoadFinder)
        }
        
        // Generate callouts for the new decision point
        sendNodeChangedEvent(from: current, to: next, along: current.edges[index], isUndo: false)
    }
    
    func goToPrevious() {
        guard let last = previous.popLast() else {
            return
        }
        
        GDATelemetry.track("preview.undo")
        
        isTransitioningSubject.value = true

        // Set the current edge to nil because the user requested to undo their last decision
        currentlyFocussedRoad.value = nil
        
        stopWands()
        
        // Update the current decision point (note that we don't update the history because we are undoing the last decision)
        let current = currentDecisionPoint.value
        currentDecisionPoint.value = last.decisionPoint
        
        locationDelegate?.locationProvider(self, didUpdateLocation: last.decisionPoint.node.location)
        
        // Generate callouts for the new decision point
        sendNodeChangedEvent(from: current, to: last.decisionPoint, along: last.selectedEdge, isUndo: true)
    }
    
    private func sendNodeChangedEvent(from: DecisionPoint, to: DecisionPoint, along: DecisionPoint.EdgeData, isUndo: Bool) {
        var previousEdgeData: DecisionPoint.EdgeData?
        
        // Calculate the previous direction of travel
        if previous.count > 1 {
            previousEdgeData = previous[previous.count - 2].selectedEdge
        }
        
        // Generate callouts for the new decision point
        if let key = beaconKey, let beacon = SpatialDataCache.referenceEntityByKey(key) {
            let location = beacon.closestLocation(from: to.node.location)
            let distance = to.node.location.distance(from: location)
            let arrivedAtBeacon = distance < 15.0
            
            delegate?.process(PreviewNodeChangedEvent(from: from, to: to, along: along, previousEdgeData: previousEdgeData, isUndo: isUndo) { _ in
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    // Only send the beacon update event we are in the started state (e.g. not paused)
                    guard self.isStartedSubject.value else {
                        self.isTransitioningSubject.value = false
                        return
                    }
                    
                    self.sendBeaconUpdateEvent(location: location, distance: distance, arrived: arrivedAtBeacon)
                }
            })
        } else {
            delegate?.process(PreviewNodeChangedEvent(from: from, to: to, along: along, previousEdgeData: previousEdgeData, isUndo: isUndo) { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.isTransitioningSubject.value = false
                    self?.startWands()
                }
            })
        }
    }
    
    private func sendBeaconUpdateEvent(location: CLLocation, distance: CLLocationDistance, arrived: Bool) {
        if arrived && destinationManager.isAudioEnabled {
            destinationManager.toggleDestinationAudio(true)
        }
        
        delegate?.process(PreviewBeaconUpdatedEvent(location: location, distance: distance, arrived: arrived) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isTransitioningSubject.value = false
                self?.startWands()
            }
        })
    }
    
    private func pausePreview() {
        // Only pause if the preview is already started
        guard isActive && isStartedSubject.value else {
            return
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        isStartedSubject.value = false
        
        // If there is a beacon set, mute it
        if destinationManager.isDestinationSet, destinationManager.isAudioEnabled {
            destinationManager.toggleDestinationAudio(true)
            didPauseBeaconOnPause = true
        }
        
        // Stop the haptics
        stopWands()
        
        delegate?.process(PreviewPausedEvent())
    }
    
    private func resumePreview() {
        // Only resume if the preview is already paused
        guard isActive && !isStartedSubject.value else {
            return
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        isStartedSubject.value = false
        
        delegate?.process(PreviewResumedEvent(at: currentDecisionPoint.value) { [weak self] _ in
            DispatchQueue.main.async {
                self?.onResumed()
            }
        })
    }
    
    private func onResumed() {
        isStartedSubject.value = true
        
        // If there was a beacon set and not muted, unmute it
        if destinationManager.isDestinationSet, !destinationManager.isAudioEnabled, didPauseBeaconOnPause {
            destinationManager.toggleDestinationAudio(true)
            didPauseBeaconOnPause = false
        }
        
        startWands()
    }
    
    private func startWands() {
        // Only allow the wand to start if we are in the started state (e.g. not paused)
        guard isStartedSubject.value else {
            return
        }
        
        let compassTargets = (0 ..< 12).map { WandTarget(CompassOrientation(bearing: Double($0) * 30.0)) }
        compassWand.start(with: compassTargets, heading: AppContext.shared.geolocationManager.heading(orderedBy: [.device]))
        
        // When the callouts are done, start the wand experience at the new intersection
        let roadHeading = AppContext.shared.geolocationManager.heading(orderedBy: [.device])
        let roadTargets = currentDecisionPoint.value.edges.map { (edge) -> WandTarget in
            if edge.isSupported {
                return WandTarget(edge.direction, window: 60.0)
            } else {
                return WandTarget(edge.direction)
            }
        }
        
        roadWand.start(with: roadTargets, heading: roadHeading)
    }
    
    private func stopWands() {
        // Stop feedback from the wand until we get to the next intersection
        roadWand.stop()
        compassWand.stop()
        
        if let beacon = roadWandBeacon {
            AppContext.shared.audioEngine.stop(beacon)
            roadWandBeacon = nil
        }
    }
}

// MARK: - WandDelegate

extension PreviewBehavior: WandDelegate {
    func wandDidStart(_ wand: Wand) {
        // Only allow the wand to start if we are in the started state (e.g. not paused)
        guard isStartedSubject.value else {
            // Stop the wand. It will be restarted when the preview is resumed
            wand.stop()
            return
        }
        
        // Check to make sure this is a wand event for a road targets
        guard let wand = wand as? PreviewWand, wand !== compassWand else {
            return
        }
        
        // Set up the ambient audio for the road finder
        let silentDistance = 15.0
        let maxDistance = roadWindow / 2 - silentDistance
        
        PreviewWandAsset.selector = { [weak self] input -> (PreviewWandAsset, PreviewWandAsset.Volume)? in
            if case .heading(let userHeading, _) = input {
                guard let `self` = self, let heading = userHeading else {
                    return (PreviewWandAsset.noTarget, 0.0)
                }
                
                if self.currentlyFocussedRoad.value == nil {
                    return (PreviewWandAsset.noTarget, 0.0)
                }
                
                let distance = self.roadWand.angleFromCurrentTarget(heading) ?? 0.0
                let volume = distance < silentDistance ? 1.0 : 1.0 - max(min((distance - silentDistance) / maxDistance, 1.0), 0.0)
                
                return (PreviewWandAsset.noTarget, Float(volume))
            }
            
            return nil
        }
        
        guard let beacon = BeaconSound(PreviewWandAsset.self, at: currentDecisionPoint.value.node.location, isLocalized: false) else {
            return
        }
        
        roadWandBeacon = AppContext.shared.audioEngine.play(beacon, heading: AppContext.shared.geolocationManager.heading(orderedBy: [.device]))
    }
    
    func wand(_ wand: Wand, didCrossThreshold target: Orientable) {
        // Only allow wand-related feedback to occur if we are in the started state (e.g. not paused)
        guard isStartedSubject.value else {
            // This state can occur if the user puts the app in the background right after hitting "Go".
            return
        }
        
        // Check to make sure this is a wand event for a road targets
        guard let wand = wand as? PreviewWand, wand !== compassWand else {
            // This is just a compass update. Perform compass haptics
            engine.trigger(for: compassFeedbackStyle)
            engine.prepare(for: compassFeedbackStyle)
            return
        }
        
        guard let roadTarget = target as? DecisionPoint.EdgeData.Path else {
            return
        }
        
        guard let dataView = currentDecisionPoint.value.edges.first(where: { $0.direction == roadTarget }) else {
            return
        }
        
        guard dataView.isSupported else {
            delegate?.process(PreviewFoundRoadEvent(dataView))
            return
        }
        
        guard let currentRoad = currentlyFocussedRoad.value, roadTarget == currentRoad.direction else {
            return
        }
        
        // Always trigger the road haptics
        engine.trigger(for: roadFeedbackStyle)
        engine.prepare(for: roadFeedbackStyle)
        
        // But only trigger the callout once per focus session
        guard !didCalloutFocussedTarget else {
            return
        }
        
        didCalloutFocussedTarget = true
        
        delegate?.process(PreviewFoundRoadEvent(dataView) { _ in
            wand.enableLongFocusForCurrentTarget()
        })
    }
    
    func wand(_ wand: Wand, didGainFocus target: Orientable, isInitial: Bool) {
        // Only allow wand-related callouts to occur if we are in the started state (e.g. not paused)
        guard isStartedSubject.value else {
            // This state can occur if the user puts the app in the background right after hitting "Go".
            return
        }
        
        // Check to make sure this is a wand event for a road targets
        guard let wand = wand as? PreviewWand, wand !== compassWand else {
            // This is just a compass update. Return without doing anything
            return
        }
        
        guard let roadTarget = target as? DecisionPoint.EdgeData.Path else {
            return
        }
        
        guard let dataView = currentDecisionPoint.value.edges.first(where: { $0.direction == roadTarget }) else {
            return
        }
        
        if isInitial {
            // If the wand just started and we are already pointing at a valid road,
            // call it rather than waiting for the user to cross the road threshold
            didCalloutFocussedTarget = true
            
            delegate?.process(PreviewFoundRoadEvent(dataView) { _ in
                wand.enableLongFocusForCurrentTarget()
            })
        } else {
            didCalloutFocussedTarget = false
            
            if mostRecentFocussedRoad?.direction != dataView.direction {
                // If there is currently a road being called out but we have entered the
                // window for a different road, interrupt the callout. This is intended to
                // make the road finder experience less confusing when the user is moving their
                // phone quickly.
                delegate?.interruptCurrent(clearQueue: true, playHush: false)
            }
        }
        
        currentlyFocussedRoad.value = dataView
        mostRecentFocussedRoad = dataView
    }
    
    func wand(_ wand: Wand, didLongFocus target: Orientable) {
        // Only allow wand-related callouts to occur if we are in the started state (e.g. not paused)
        guard isStartedSubject.value else {
            // This state can occur if the user puts the app in the background right before the long focus event occurred
            return
        }
        
        // Check to make sure this is a wand event for a road targets
        guard let wand = wand as? PreviewWand, wand !== compassWand else {
            return
        }
        
        guard let roadTarget = target as? DecisionPoint.EdgeData.Path else {
            return
        }
        
        guard let dataView = currentlyFocussedRoad.value, roadTarget == dataView.direction else {
            return
        }
        
        delegate?.process(PreviewFoundNextIntersectionEvent(from: currentDecisionPoint.value, along: dataView))
    }
    
    func wand(_ wand: Wand, didLoseFocus target: Orientable) {
        // Check to make sure this is a wand event for a road targets
        guard let wand = wand as? PreviewWand, wand !== compassWand else {
            // This is just a compass update. Return without doing anything
            return
        }
        
        guard let roadTarget = target as? DecisionPoint.EdgeData.Path else {
            return
        }
        
        guard let dataView = currentlyFocussedRoad.value, roadTarget == dataView.direction else {
            return
        }
        
        GDLogPreviewInfo("Lost focus on road")
        currentlyFocussedRoad.value = nil
    }
}

// MARK: - LocationProvider

extension PreviewBehavior: LocationProvider {
    func startLocationUpdates() {
        // No-op - Location updates are driven by the simulation and don't require initialization
    }
    
    func stopLocationUpdates() {
        // No-op - Location updates are driven by the simulation and don't require cleanup
    }
    
    func startMonitoringSignificantLocationChanges() -> Bool {
        // `PreviewBehavior` does not support significant location changes
        return false
    }
    
    func stopMonitoringSignificantLocationChanges() {
        // No-op - `PreviewBehavior` does not support significant location changes
    }
}

// MARK: - CourseProvider

extension PreviewBehavior: CourseProvider {
    func startCourseProviderUpdates() {
        // No-op - Course updates are driven by the simulation and don't require initialization
    }
    
    func stopCourseProviderUpdates() {
        // No-op - Course updates are driven by the simulation and don't require cleanup
    }
}
