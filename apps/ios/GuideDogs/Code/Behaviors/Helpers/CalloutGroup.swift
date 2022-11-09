//
//  CalloutGroup.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol CalloutGroupDelegate: AnyObject {
    /// Used for checking if a callout should still be performed when the event processor finally gets around to playing it
    ///
    /// - Parameter callout: The callout to check
    /// - Returns: True if the callout should still be performed, false otherwise
    func isCalloutWithinRegionToLive(_ callout: CalloutProtocol) -> Bool
    
    /// Called when an individual callout is skipped (e.g. because is is no longer in the region to live)
    ///
    /// - Parameter callout: The callout that was skipped
    func calloutSkipped(_ callout: CalloutProtocol)
    
    /// Called when an individual callout is about to be started
    ///
    /// - Parameter callout: The callout that is starting
    func calloutStarting(_ callout: CalloutProtocol)
    
    /// Called when an individual callout is about to be started
    ///
    /// - Parameter callout: The callout that is starting
    /// - Parameter completed: True if the callout was completed successfully, false otherwise
    func calloutFinished(_ callout: CalloutProtocol, completed: Bool)
    
    /// Indicates that all callouts in the group were skipped as a whole (e.g. by being cleared from the queue)
    ///
    /// - Parameter group: The callout group that was skipped
    func calloutsSkipped(for group: CalloutGroup)
    
    /// Indicates that the callouts in this group have started to get called out
    ///
    /// - Parameter group: The callout group that was started
    func calloutsStarted(for group: CalloutGroup)
    
    /// Indicates that a callout group that had previous started has completed
    ///
    /// - Parameter group: The callout group that has completed
    /// - Parameter finished: Indicates if the callouts in this group were successfully completed without interruption
    func calloutsCompleted(for group: CalloutGroup, finished: Bool)
}

class CalloutGroup: Equatable {
    let id = UUID()
    let logContext: String
    
    var action: QueueAction
    let prefixCallout: CalloutProtocol?
    let callouts: [CalloutProtocol]
    
    let playModeSounds: Bool
    let stopSoundsBeforePlaying: Bool
    let calloutDelay: TimeInterval?
    let repeatingFromLocation: CLLocation?
    
    var onStart: (() -> Void)?
    var onComplete: ((Bool) -> Void)?
    
    weak var delegate: CalloutGroupDelegate?
    
    var isEmpty: Bool {
        return callouts.isEmpty
    }
    
    /// Determines if this callout group is valid to be called out. Default implementation is `true`.
    /// In most cases, if the value is `false`, this callout group can be discarded and removed from the playing queue.
    var isValid: (() -> Bool) = {
        return true
    }
    
    init(_ callouts: [CalloutProtocol], prefix: CalloutProtocol? = nil, repeatingFromLocation: CLLocation? = nil, action: QueueAction = .enqueue, playModeSounds: Bool = false, stopSoundsBeforePlaying: Bool = false, calloutDelay: TimeInterval? = nil, logContext: String) {
        self.action = action
        self.callouts = callouts
        self.prefixCallout = prefix
        self.repeatingFromLocation = repeatingFromLocation
        self.playModeSounds = playModeSounds
        self.stopSoundsBeforePlaying = stopSoundsBeforePlaying
        self.calloutDelay = calloutDelay
        self.logContext = logContext
    }
    
    static func == (lhs: CalloutGroup, rhs: CalloutGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var empty: CalloutGroup {
        return CalloutGroup([], logContext: "")
    }
    
}
