//
//  PreviewWand.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

struct WandTarget {
    let orientable: Orientable
    let focussable: Bool
    let targetRange: ClosedRange<Double>
    
    init(_ orientable: Orientable, window: Double) {
        self.orientable = orientable
        self.focussable = true
        targetRange = (orientable.bearing - window / 2) ... (orientable.bearing + window / 2)
    }
    
    init(_ orientable: Orientable) {
        self.orientable = orientable
        self.focussable = false
        
        // Use a default window but disable the ability to focus on the target when in the window
        targetRange = (orientable.bearing - 10) ... (orientable.bearing + 10)
    }
    
    /// Checks if the the arc from one angle to another crosses over the target bearing
    ///
    /// - Parameters:
    ///   - from: Starting angle (expected to be in the range [0,360])
    ///   - to: Ending angle (expected to be in the range [0,360])
    /// - Returns: True if the arc passed over the target's bearing
    func passedThreshold(from: Double, to: Double) -> Bool {
        let lowerBound = min(from, to)
        let upperBound = max(from, to)
        
        if abs(upperBound - lowerBound) > 180.0 {
            return (upperBound ... 360.0).containsAngle(orientable.bearing) || (0.0 ..< lowerBound).containsAngle(orientable.bearing)
        } else {
            return (lowerBound ..< upperBound).containsAngle(orientable.bearing)
        }
    }
}

class PreviewWand: Wand {
    
    private var heading: HeadingNotifier?
    private var targets: [WandTarget] = []
    private var focusedTargetIndex: Array<WandTarget>.Index?
    private var previousHeading: Double?
    private var longFocusTimer: Timer?
    private var canEnableLongFocus = false
    private var hasStarted = false
    
    weak var delegate: WandDelegate?
    
    var isActive: Bool {
        return heading != nil && targets.count > 0
    }
    
    func start(with newTargets: [WandTarget], heading headingProvider: HeadingNotifier) {
        guard newTargets.count > 0 else {
            return
        }
        
        // Get the headings from the phone
        heading = headingProvider
        heading?.onHeadingDidUpdate { [weak self] (heading) in
            guard let headingValue = heading?.value else {
                return
            }
            
            self?.process(headingValue)
        }
        
        targets = newTargets
        
        if let value = heading?.value {
            // Propagate the current heading immediately so we don't have to wait for the
            // user to move when they first start the road finder
            DispatchQueue.main.async { [weak self] in
                self?.process(value, isInitial: true)
            }
        }
    }
    
    func stop() {
        heading = nil
        previousHeading = nil
        focusedTargetIndex = nil
        targets.removeAll()
        hasStarted = false
    }
    
    func enableLongFocusForCurrentTarget() {
        guard let current = focusedTargetIndex, canEnableLongFocus, longFocusTimer == nil else {
            return
        }
        
        guard targets[current].focussable else {
            return
        }
        
        let orientable = targets[current].orientable
        
        DispatchQueue.main.async { [weak self] in
            GDLogAppVerbose("[WAND] Setting long focus timer")
            self?.longFocusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] (timer) in
                defer {
                    timer.invalidate()
                    self?.longFocusTimer = nil
                    self?.canEnableLongFocus = false
                }
                
                guard let `self` = self else {
                    return
                }
                
                self.delegate?.wand(self, didLongFocus: orientable)
            }
        }
    }
    
    /// Computes the angle between a given heading and the heading of the current target (if one exists)
    ///
    /// - Parameter heading: Input heading
    /// - Returns: The angle between a given heading and the heading of the current target, or nil if there is not a current target
    func angleFromCurrentTarget(_ heading: Double) -> Double? {
        guard let current = focusedTargetIndex else {
            return nil
        }
        
        let targetBearing = targets[current].orientable.bearing
        let absDiff = abs(targetBearing.bearing(to: heading))
        
        return absDiff < 180.0 ? absDiff : 360.0 - absDiff
    }
    
    private func process(_ heading: Double, isInitial: Bool = false) {
        defer {
            if !hasStarted {
                hasStarted = true
                delegate?.wandDidStart(self)
            }
        }
        
        // Make sure this is a valid heading value
        let currentHeading = heading.normalizeAngle()
        
        defer {
            previousHeading = currentHeading
        }
        
        // Check if the heading is within the window for any targets. If not, signal that we lost focus on the current target
        guard let targetIndex = targets.firstIndex(where: { $0.targetRange.containsAngle(currentHeading) }) else {
            // If the user was previously in a window, clear it
            if let lost = focusedTargetIndex {
                if targets[lost].focussable {
                    delegate?.wand(self, didLoseFocus: targets[lost].orientable)
                }
                
                longFocusTimer?.invalidate()
                longFocusTimer = nil
                canEnableLongFocus = false
                focusedTargetIndex = nil
            }
            
            return
        }
        
        let target = targets[targetIndex]
        
        // Check if we gained focus on a new target
        guard targetIndex == focusedTargetIndex else {
            focusedTargetIndex = targetIndex
            
            if target.focussable {
                delegate?.wand(self, didGainFocus: target.orientable, isInitial: isInitial)
            }
            
            longFocusTimer?.invalidate()
            longFocusTimer = nil
            canEnableLongFocus = false
            return
        }
        
        // Check if the wand passed over the target's exact bearing
        if let previousHeading = previousHeading, target.passedThreshold(from: previousHeading, to: currentHeading) {
            delegate?.wand(self, didCrossThreshold: target.orientable)
            canEnableLongFocus = target.focussable
        }
    }
    
}

private extension Range where Bound == Double {
    func containsAngle(_ angle: Double) -> Bool {
        if self.contains(angle) {
            return true
        } else if self.lowerBound < 0 {
            return ((lowerBound + 360.0) ..< (upperBound + 360.0)).contains(angle)
        } else if self.upperBound > 360.0 {
            return ((lowerBound - 360.0) ..< (upperBound - 360.0)).contains(angle)
        } else {
            return false
        }
    }
}

private extension ClosedRange where Bound == Double {
    func containsAngle(_ angle: Double) -> Bool {
        if self.contains(angle) {
            return true
        } else if self.lowerBound < 0 {
            return ((lowerBound + 360.0) ... (upperBound + 360.0)).contains(angle)
        } else if self.upperBound > 360.0 {
            return ((lowerBound - 360.0) ... (upperBound - 360.0)).contains(angle)
        } else {
            return false
        }
    }
}

private extension Double {
    func normalizeAngle() -> Double {
        if (0.0 ... 360.0).contains(self) {
            return self
        }
        
        return fmod(self + 360.0, 360.0)
    }
}
