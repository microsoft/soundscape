//
//  EventProcessor.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let behaviorActivated = Notification.Name("GDABehaviorActivated")
    static let behaviorDeactivated = Notification.Name("GDABehaviorDeactivated")
}

class EventProcessor: CalloutStateMachineDelegate, BehaviorDelegate {
    
    struct Keys {
        static let behavior = "GDABehaviorKey"
    }
    
    private var calloutQueue = Queue<CalloutGroup>()
    private var currentCallouts: CalloutGroup?
    
    private let stateMachine: CalloutStateMachine
    private unowned let audioEngine: AudioEngineProtocol
    private unowned let data: SpatialDataProtocol
    
    /// Current top level behavior in the behavior stack
    private(set) var activeBehavior: Behavior
    
    /// Indicates if there is currently an active behavior running
    var isCustomBehaviorActive: Bool {
        return !(activeBehavior is SoundscapeBehavior)
    }
    
    private var beaconId: String?
    
    // MARK: Setup and Initialization
    
    init(activeBehavior: Behavior, stateMachine: CalloutStateMachine, audioEngine: AudioEngineProtocol, data: SpatialDataProtocol) {
        self.activeBehavior = activeBehavior
        self.stateMachine = stateMachine
        self.audioEngine = audioEngine
        self.data = data
        
        // Setup the delegate for the base Soundscape behavior
        activeBehavior.delegate = self
        stateMachine.delegate = self
    }
    
    /// Starts the event processor by activating the default Soundscape behavior. This method
    /// should be called after the audio engine is started so that any callouts that are
    /// generated can be played
    func start() {
        guard !activeBehavior.isActive else {
            return
        }
        
        // Activate the default root behavior
        activeBehavior.activate(with: nil)
    }
    
    /// Activates a custom behavior
    ///
    /// - Parameter behavior: The custom behavior to activate
    func activateCustom(behavior: Behavior) {
        // For the time being, only allow one behavior to be layered
        // on top of the default behavior
        if isCustomBehaviorActive {
            deactivateCustom()
        }
        
        GDLogEventProcessorInfo("Activating the \(behavior) behavior")
        
        let parent = activeBehavior
        activeBehavior = behavior
        
        behavior.delegate = self
        behavior.activate(with: parent)
        
        NotificationCenter.default.post(name: Notification.Name.behaviorActivated, object: self, userInfo: [Keys.behavior: behavior])
        
        // Process an event for indicating that the behavior has started
        process(BehaviorActivatedEvent())
        
        // Make sure the new behavior has the current location... (only really matters in GPX simulation)
        if let location = AppContext.shared.geolocationManager.location {
            process(LocationUpdatedEvent(location))
        }
    }
    
    /// If there is currently an active behavior, calling this method will save it's state
    /// and turn off the behavior (setting the active behavior to nil and releasing it's memory).
    func deactivateCustom() {
        guard isCustomBehaviorActive else {
            return
        }
        
        GDLogEventProcessorInfo("Deactivating the \(activeBehavior) behavior")
        
        // Let the active behavior know it is about to be deactivated so it can handle any necessary state clean-up
        activeBehavior.willDeactivate()
        
        // Give the behavior a chance to respond to the fact that it is being deactivated...
        let event = BehaviorDeactivatedEvent { [weak self] _ in
            DispatchQueue.main.async {
                self?.finishDeactivatingCustom()
            }
        }
        
        if activeBehavior.manualGenerators.contains(where: { $0.respondsTo(event) }) {
            process(event)
        } else {
            finishDeactivatingCustom()
        }
    }
    
    private func finishDeactivatingCustom() {
        guard isCustomBehaviorActive else {
            return
        }
        
        guard let parent = activeBehavior.deactivate() else {
            return
        }
        
        activeBehavior = parent
        
        calloutQueue.clear()
        stateMachine.hush(playSound: true)
        
        NotificationCenter.default.post(name: Notification.Name.behaviorDeactivated, object: self)
    }
    
    func sleep() {
        var behavior: Behavior? = activeBehavior
        
        while behavior != nil {
            behavior?.sleep()
            behavior = behavior?.parent
        }
        
        hush(playSound: false)
    }
    
    func wake() {
        var behavior: Behavior? = activeBehavior
        
        while behavior != nil {
            behavior?.wake()
            behavior = behavior?.parent
        }
        
        process(GlyphEvent(.appLaunch))
    }
    
    func isActive<T: Behavior>(behavior: T.Type) -> Bool {
        return activeBehavior is T
    }
    
    // MARK: Event Processing
    
    /// Handles an event by passing it to the active behavior (or the default behavior if
    /// no custom behavior is active)
    ///
    /// - Parameter event: The event to process
    func process(_ event: Event) {
        // Log events
        switch event {
        case let locEvent as LocationUpdatedEvent:
            GDLogEventProcessorInfo("Processing \(event.name): \(locEvent.location)")
            
        default:
            GDLogEventProcessorInfo("Processing \(event.name)")
        }
        
        // Handle normal events
        activeBehavior.handleEvent(event) { actions in
            guard let actions = actions else {
                return
            }

            // The completion callback is executing in the context of the active behavior's
            // dispatch queue, so we should move back to the main queue before continuing...
            DispatchQueue.main.async {
                let interrupt = actions.contains {
                    if case .interruptAndClearQueue = $0 {
                        return true
                    }
                    
                    return false
                }
                
                if interrupt {
                    self.interruptCurrent(clearQueue: true, playHush: false)
                    return
                }
                
                for case let .playCallouts(calloutGroup) in actions {
                    self.enqueue(calloutGroup)
                }
                
                for case let .processEvents(events) in actions {
                    for event in events {
                        self.process(event)
                    }
                }
            }
        }
    }
    
    // MARK: Callout Queueing
    
    /// Helper method for enqueueing multiple `CalloutGroup` objects at once. The value
    /// the enqueue style of the first `CalloutGroup` in the array is maintained as specified,
    /// but all remaining items in the array will be enqueued with the `.enqueue`
    /// style.
    ///
    /// - Parameters:
    ///   - callouts: `CalloutGroup` objects to enqueue
    private func enqueue(_ callouts: [CalloutGroup]) {
        // Enqueue the first group with the specified style
        guard callouts.count > 0 else {
            GDLogWarn(.eventProcessor, "Attempted to enqueue and enmpty group of callouts!")
            return
        }
        
        // Override the enqueue style of all callouts except the first to be .enqueue
        callouts.dropFirst().forEach({ $0.action = .enqueue })
        
        // Enqueue all the callouts
        callouts.forEach({ enqueue($0) })
    }
    
    private func enqueue(_ callouts: CalloutGroup) {
        GDLogEventProcessorInfo("Enqueueing \(callouts.callouts.count) callouts with style \(callouts.action)")
        
        switch callouts.action {
        case .interruptAndClear:
            if currentCallouts != nil && stateMachine.isPlaying {
                clearQueue()
                calloutQueue.enqueue(callouts)
                stateMachine.stop()
                return
            }
            
        case .clear:
            clearQueue()
            
        default:
            break
        }
        
        calloutQueue.enqueue(callouts)
        
        tryStartCallouts()
    }
    
    private func clearQueue() {
        while !calloutQueue.isEmpty {
            if let group = calloutQueue.dequeue() {
                group.delegate?.calloutsSkipped(for: group)
            }
        }
    }
    
    private func nextValidCalloutGroup() -> CalloutGroup? {
        while !calloutQueue.isEmpty {
            guard let calloutGroup = calloutQueue.dequeue() else {
                return nil
            }
            
            if calloutGroup.isValid() {
                return calloutGroup
            }
            
            // Discard invalid callout group
            GDLogEventProcessorInfo("Discarding invalid callout group with id: \(calloutGroup.id), context: \(calloutGroup.logContext)")
            calloutGroup.delegate?.calloutsSkipped(for: calloutGroup)
        }
        
        return nil
    }
    
    // MARK: Callout State Machine
    
    private func tryStartCallouts() {
        guard !stateMachine.isPlaying else {
            GDLogEventProcessorInfo("Can't start callouts - state machine is playing (current state: \(stateMachine.currentState))")
            return
        }
        
        currentCallouts = nextValidCalloutGroup()
        
        guard let currentCallouts = currentCallouts else {
            GDLogEventProcessorInfo("Can't start callouts - no callouts to start")
            return
        }
        
        GDLogEventProcessorInfo("Starting callouts")
        
        stateMachine.start(currentCallouts)
    }
    
    func calloutsDidFinish(id: UUID) {
        GDLogEventProcessorInfo("Callouts finished (\(id))")
        
        if let current = currentCallouts, current.id == id {
            current.delegate?.calloutsCompleted(for: current, finished: true)
            currentCallouts = nil
        }
        
        if !calloutQueue.isEmpty {
            tryStartCallouts()
        }
    }
    
    // MARK: - General Controls
    
    func interruptCurrent(clearQueue clear: Bool = true, playHush: Bool = false) {
        GDLogVerbose(.eventProcessor, "Interrupting current callouts")
        
        if playHush {
            stateMachine.hush(playSound: playHush)
        } else {
            stateMachine.stop()
        }
        
        if let currentCallouts = currentCallouts {
            currentCallouts.delegate?.calloutsCompleted(for: currentCallouts, finished: false)
        }
        
        currentCallouts = nil
        
        if clear {
            clearQueue()
        }
    }
    
    func hush(playSound: Bool = true, hushBeacon: Bool = true) {
        GDLogInfo(.eventProcessor, "Hushing event processor")
        
        if hushBeacon, data.destinationManager.isAudioEnabled, activeBehavior is SoundscapeBehavior {
            if !data.destinationManager.toggleDestinationAudio(automatic: false) {
                GDLogError(.eventProcessor, "Unable to hush destination audio - hush command")
            }
        }
        
        interruptCurrent(playHush: playSound)
    }
    
    @discardableResult
    func toggleAudio() -> Bool {
        let isDiscreteAudioPlaying = audioEngine.isDiscreteAudioPlaying
        let isBeaconPlaying = data.destinationManager.isAudioEnabled
        let isDestinationSet = data.destinationManager.destinationKey != nil
        
        // Check if there is anything to toggle
        guard isDiscreteAudioPlaying || isDestinationSet || isBeaconPlaying else {
            return false
        }
        
        // Toggle beacon if needed
        // If audio is playing but the beacon is muted, we mute the audio and DO NOT un-mute the beacon
        if isDestinationSet && !(isDiscreteAudioPlaying && !isBeaconPlaying) {
            data.destinationManager.toggleDestinationAudio(automatic: false)
            
            // If audio was playing, the command processor's `hush` method will output the effect sound
            // If not, we force the hush effect sound when unmuting the beacon
            if isBeaconPlaying && !isDiscreteAudioPlaying {
                process(GlyphEvent(.hush))
            }
        }
        
        // Hush callouts if needed
        if isDiscreteAudioPlaying {
            guard !AppContext.shared.eventProcessor.isCustomBehaviorActive else {
                interruptCurrent(clearQueue: true, playHush: true)
                return true
            }
            
            interruptCurrent(playHush: true)
        }
        
        return true
    }
}
