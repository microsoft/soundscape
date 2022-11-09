//
//  CalloutStateMachine.swift
//  Soundscape
//
//  This class manages the callout of a list of callouts, one after another,
//  with the ability to hush or restart the whole set of callouts.
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

private enum State: String {
    case unknown = "[Unknown]"
    case wildcard = "*"
    case off = "[Off]"
    case start = "[Start]"
    case starting = "[Starting]"
    case stop = "[Stop]"
    case stopping = "[Stopping]"
    case announceCallout = "[AnnounceCallout]"
    case announcingCallout = "[AnnouncingCallout]"
    case delayingCalloutAnnounced = "[DelayingCalloutAnnounced]"
    case complete = "[Complete]"
    case failed = "[Failed]"
}

private enum StateMachineEvent: String {
    case start = "(Start)"
    case started = "(Started)"
    case stop = "(Stop)"
    case stopped = "(Stopped)"
    case hush = "(Hush)"
    case delayCalloutAnnounced = "(CalloutDelay)"
    case calloutAnnounced = "(CalloutAnnounced)"
    case complete = "(Complete)"
    case completed = "(Completed)"
    case failed = "(Failed)"
}

protocol CalloutStateMachineDelegate: AnyObject {
    func calloutsDidFinish(id: UUID)
}

class CalloutStateMachine {
    
    // MARK: Properties
    
    weak var delegate: CalloutStateMachineDelegate?
    
    private weak var geo: GeolocationManagerProtocol!
    private weak var history: CalloutHistory!
    private weak var motionActivityContext: MotionActivityProtocol!
    private weak var audioEngine: AudioEngineProtocol!
    
    private var hushed = false
    private var playHushedSound = false
    private var stateMachine: GDAStateMachine!
    private var calloutGroup: CalloutGroup?
    private var calloutIterator: IndexingIterator<[CalloutProtocol]>?
    
    private var lastGroupID: UUID?
    
    var currentState: String {
        return stateMachine?.currentState?.name ?? State.unknown.rawValue
    }
    
    var isPlaying: Bool {
        return stateMachine.currentState.name != State.off.rawValue
    }
    
    // MARK: Initialization
    
    init(audioEngine engine: AudioEngineProtocol,
         geo: GeolocationManagerProtocol,
         motionActivityContext motion: MotionActivityProtocol,
         history calloutHistory: CalloutHistory) {
        history = calloutHistory
        audioEngine = engine
        motionActivityContext = motion
        self.geo = geo
        
        stateMachine = buildStateMachine()
    }
    
    // MARK: Methods
    
    func start(_ callouts: CalloutGroup) {
        // The state machine must be stopped before you can call start(...)
        guard !isPlaying else {
            GDLogVerbose(.stateMachine, "Unable to start callout group. State machine is currently in state: \(stateMachine.currentState.name ?? State.unknown.rawValue)")
            return
        }
        
        calloutGroup = callouts
        hushed = false
        playHushedSound = false
        
        callouts.onStart?()
        stateMachine.fireEvent(.start)
    }
    
    func hush(playSound: Bool = false) {
        hushed = true
        
        if playSound {
            playHushedSound = true
        }
        
        stateMachine.fireEvent(.hush)
    }
    
    func stop() {
        if isPlaying {
            stateMachine.fireEvent(.stop)
        }
    }
    
    private func buildStateMachine() -> GDAStateMachine {
        let states: [GDAStateMachineState] = [
            stateOff(),
            stateStart(),
            stateStarting(),
            stateStop(),
            stateStopping(),
            stateAnnounceCallout(),
            stateAnnouncingCallout(),
            stateDelayingCalloutAnnounced(),
            stateComplete(),
            stateFailed()
        ]
        
        let events: [GDAStateMachineEvent] = [
            // START
            GDAStateMachine.event(name: .start,
                                  transitions: [.off: .start]),
            
            // STARTING
            GDAStateMachine.event(name: .started, transitions: [.starting: .announceCallout]),
            
            // HUSH
            GDAStateMachine.event(name: .hush,
                                  transitions: [.wildcard: .stop]),
            
            // DELAY CALLOUT ANNOUNCED
            GDAStateMachine.event(name: .delayCalloutAnnounced,
                                  transitions: [.announcingCallout: .delayingCalloutAnnounced,
                                                .complete: .complete,
                                                .off: .off
                                  ]),
            
            // EXPLORE QUADRANT RESULT ANNOUNCED
            GDAStateMachine.event(name: .calloutAnnounced,
                                  transitions: [.announcingCallout: .announceCallout,
                                                .delayingCalloutAnnounced: .announceCallout,
                                                .complete: .complete,
                                                .off: .off]),
            
            // STOP
            GDAStateMachine.event(name: .stop, transitions: [
                .starting: .stop,
                .announcingCallout: .stop,
                .complete: .off,
                .off: .off,
                .wildcard: .complete
            ]),
            
            // STOPPING
            GDAStateMachine.event(name: .stopped, transitions: [.stopping: .complete]),
            
            // COMPLETE
            GDAStateMachine.event(name: .complete, transitions: [.wildcard: .complete]),
            
            // COMPLETED
            GDAStateMachine.event(name: .completed, transitions: [.complete: .off]),
            
            // FAILED
            GDAStateMachine.event(name: .failed, transitions: [.wildcard: .failed])
        ]
        
        return GDAStateMachine(name: "CalloutMachine", states: states, events: events)
    }
}

extension CalloutStateMachine {
    
    private func stateOff() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .off, enter: { [weak self] (_, _, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.off)")
            
            guard let strongSelf = self else {
                return
            }
            
            if let lastGroupID = strongSelf.lastGroupID {
                strongSelf.lastGroupID = nil
                DispatchQueue.main.async {
                    strongSelf.delegate?.calloutsDidFinish(id: lastGroupID)
                }
            }
        })
    }
    
    private func stateStart() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .start, enter: { [weak self] (_, nextStateName, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.start)")
            
            guard let strongSelf = self else {
                return
            }
            
            guard let calloutGroup = strongSelf.calloutGroup else {
                nextStateName?.pointee = State.failed.rawValue as NSString
                return
            }
            
            // Stop current sounds if needed
            if calloutGroup.stopSoundsBeforePlaying {
                strongSelf.audioEngine.stopDiscrete()
            }
            
            calloutGroup.delegate?.calloutsStarted(for: calloutGroup)
            
            // Prepare the iterator for the callouts
            strongSelf.calloutIterator = calloutGroup.callouts.makeIterator()
            
            // Play the sounds indicating that the mode has started
            var sounds: [Sound] = calloutGroup.playModeSounds ? [GlyphSound(.enterMode)] : []
            
            if let prefixSounds = calloutGroup.prefixCallout?.sounds(for: strongSelf.geo?.location) {
                sounds.append(contentsOf: prefixSounds.soundArray)
            }
            
            if sounds.count > 0 {
                strongSelf.audioEngine.play(Sounds(sounds)) { (success) in
                    guard strongSelf.currentState != State.stopping.rawValue else {
                        GDLogVerbose(.stateMachine, "Callout interrupted. Stopping...")
                        strongSelf.stateMachine.fireEvent(.stopped)
                        calloutGroup.onComplete?(false)
                        return
                    }
                    
                    guard strongSelf.currentState != State.off.rawValue else {
                        GDLogVerbose(.stateMachine, "Callouts immediately interrupted. Cleaning up...")
                        calloutGroup.onComplete?(false)
                        return
                    }
                    
                    guard success else {
                        GDLogVerbose(.stateMachine, "Callout did not finish playing successfully. Terminating state machine...")
                        strongSelf.stateMachine.fireEvent(.failed)
                        return
                    }
                    
                    GDLogVerbose(.stateMachine, "Enter mode sound played")
                    strongSelf.stateMachine.fireEvent(.started)
                }
                
                // Transition to the state to allow mode sounds and prefix sounds to play
                nextStateName?.pointee = State.starting.rawValue as NSString
            } else {
                // Transition to the state to announce callouts
                nextStateName?.pointee = State.announceCallout.rawValue as NSString
            }
        })
    }
    
    private func stateStarting() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .starting, enter: { (_, _, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.starting)")
        })
    }
    
    private func stateStop() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .stop, enter: { [weak self] (_, nextStateName, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.stop)")
            
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.audioEngine.isDiscreteAudioPlaying {
                // The audio engine is currently playing a discrete sound. Stop it and then move to the .stopping state and wait
                // until the sound is actually stopped (see the completion handlers passed to audioEngine.play() in the .start
                // and .announceCallout states).
                strongSelf.audioEngine.stopDiscrete(with: strongSelf.hushed && strongSelf.playHushedSound ? GlyphSound(.hush) : nil)
                nextStateName?.pointee = State.stopping.rawValue as NSString
            } else {
                // In this case, discrete audio isn't currently playing, but we might be between sounds, so still call stopDiscrete in
                // order to clear the sounds queue in the audio engine before moving to the complete state
                strongSelf.audioEngine.stopDiscrete(with: strongSelf.hushed && strongSelf.playHushedSound ? GlyphSound(.hush) : nil)
                nextStateName?.pointee = State.complete.rawValue as NSString
            }
        })
    }
    
    private func stateStopping() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .stopping, enter: { (_, _, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.stopping)")
        })
    }
    
    private func stateAnnounceCallout() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .announceCallout, enter: { [weak self] (_, nextStateName, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.announceCallout)")
            
            guard let strongSelf = self else {
                return
            }
            
            guard let calloutGroup = strongSelf.calloutGroup else {
                nextStateName?.pointee = State.failed.rawValue as NSString
                return
            }
            
            guard let callout = strongSelf.calloutIterator?.next() else {
                calloutGroup.onComplete?(true)
                nextStateName?.pointee = State.complete.rawValue as NSString
                return
            }
            
            // If this callout is not within the region to live, skip to the next callout
            if let delegate = calloutGroup.delegate, !delegate.isCalloutWithinRegionToLive(callout) {
                calloutGroup.delegate?.calloutSkipped(callout)
                nextStateName?.pointee = State.announceCallout.rawValue as NSString
                return
            }
            
            calloutGroup.delegate?.calloutStarting(callout)
            strongSelf.history?.insert(callout)
            
            let sounds: Sounds
            if let repeatLocation = calloutGroup.repeatingFromLocation {
                sounds = callout.sounds(for: repeatLocation, isRepeat: true)
            } else {
                sounds = callout.sounds(for: strongSelf.geo?.location, automotive: strongSelf.motionActivityContext.isInVehicle)
            }
            
            strongSelf.audioEngine.play(sounds) { (success) in
                calloutGroup.delegate?.calloutFinished(callout, completed: success)
                
                guard strongSelf.currentState != State.stopping.rawValue else {
                    GDLogVerbose(.stateMachine, "Callout interrupted. Stopping...")
                    strongSelf.stateMachine.fireEvent(.stopped)
                    calloutGroup.onComplete?(false)
                    return
                }
                
                guard strongSelf.currentState != State.off.rawValue else {
                    GDLogVerbose(.stateMachine, "Callouts immediately interrupted. Cleaning up...")
                    calloutGroup.onComplete?(false)
                    return
                }
                
                guard success else {
                    GDLogVerbose(.stateMachine, "Callout did not finish playing successfully. Terminating state machine...")
                    calloutGroup.onComplete?(false)
                    strongSelf.stateMachine.fireEvent(.failed)
                    return
                }
                
                strongSelf.stateMachine.fireEvent(.delayCalloutAnnounced)
            }
            
            CalloutStateMachineLogger.log(callout: callout, context: strongSelf.calloutGroup?.logContext)
            
            nextStateName?.pointee = State.announcingCallout.rawValue as NSString
        })
    }
    
    private func stateAnnouncingCallout() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .announcingCallout, enter: { (_, _, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.announcingCallout)")
        })
    }
    
    private func stateDelayingCalloutAnnounced() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .delayingCalloutAnnounced, enter: { [weak self] (_, nextStateName, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.delayingCalloutAnnounced)")
            
            guard let strongSelf = self else {
                return
            }
            
            if let delay = strongSelf.calloutGroup?.calloutDelay, delay >= 0.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let strongSelf = self, strongSelf.currentState == State.delayingCalloutAnnounced.rawValue else {
                        return
                    }
                    
                    strongSelf.stateMachine.fireEvent(.calloutAnnounced)
                }
            } else {
                nextStateName?.pointee = State.announceCallout.rawValue as NSString
            }
        })
    }
    
    private func stateComplete() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .complete, enter: { [weak self] (_, nextStateName, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.complete)")
            
            guard let strongSelf = self else {
                return
            }
            
            if !strongSelf.hushed && strongSelf.calloutGroup?.playModeSounds ?? false {
                strongSelf.audioEngine.play(GlyphSound(.exitMode)) { (_) in
                    GDLogVerbose(.stateMachine, "Exit mode sound played")
                    
                    strongSelf.lastGroupID = strongSelf.calloutGroup?.id
                    strongSelf.calloutIterator = nil
                    strongSelf.calloutGroup = nil
                    strongSelf.stateMachine.fireEvent(.completed)
                }
            } else {
                strongSelf.lastGroupID = strongSelf.calloutGroup?.id
                strongSelf.calloutIterator = nil
                strongSelf.calloutGroup = nil
                nextStateName?.pointee = State.off.rawValue as NSString
            }
        })
    }
    
    /// This is the same as COMPLETE except no additional sounds may be played
    private func stateFailed() -> GDAStateMachineState {
        return GDAStateMachine.state(name: .failed, enter: { [weak self] (_, nextStateName, _) in
            GDLogVerbose(.stateMachine, "Entering state: \(State.failed)")
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.lastGroupID = strongSelf.calloutGroup?.id
            strongSelf.calloutIterator = nil
            strongSelf.calloutGroup = nil
            nextStateName?.pointee = State.off.rawValue as NSString
        })
    }
    
}

extension GDAStateMachine {
    fileprivate func fireEvent(_ event: StateMachineEvent) {
        self.fireEvent(withName: event.rawValue)
    }
    
    fileprivate class func state(name: State, timeout: TimeInterval = 0.0, enter: GDAStateEnterAction? = nil, exit: GDAStateExitAction? = nil) -> GDAStateMachineState {
        return GDAStateMachineState(name: name.rawValue, timeout: timeout, enterAction: enter, exitAction: exit)
    }
    
    fileprivate class func event(name: StateMachineEvent, transitions stateTransitions: [State: State]) -> GDAStateMachineEvent {
        var transitions: [String: String] = [:]
        
        for (start, end) in stateTransitions {
            transitions[start.rawValue] = end.rawValue
        }
        
        return GDAStateMachineEvent(name: name.rawValue, transitions: transitions)
    }
}

private class CalloutStateMachineLogger {
    class func log(callout: CalloutProtocol, context: String?) {
        var properties = ["type": callout.logCategory,
                          "activity": AppContext.shared.motionActivityContext.currentActivity.rawValue,
                          "audio.output": AppContext.shared.audioEngine.outputType]
        
        if let context =  context {
            properties["context"] = context
        }
        
        GDATelemetry.track("callout", with: properties)
    }
}
