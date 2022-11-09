//
//  HapticEngine.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreHaptics

/// A helper/wrapper class for the three concrete implementations of `UIFeedbackGenerator`. `HapticEngine`
/// acts as a unified API for creating and triggering feedback generators.
class HapticEngine {
    private var generators: [UIFeedbackGenerator] = []
    
    enum FeedbackStyle {
        // UIImpactFeedbackGenerator
        case impactHeavy
        case impactLight
        case impactMedium
        case impactRigid
        case impactSoft
        
        // UISelectionFeedbackGenerator
        case selection
        
        // UINotificationFeedbackGenerator
        case error
        case success
        case warning
        
        func toImpactFeedbackStyle() -> UIImpactFeedbackGenerator.FeedbackStyle? {
            switch self {
            case .impactHeavy: return .heavy
            case .impactLight: return .light
            case .impactMedium: return .medium
            case .impactRigid: return .rigid
            case .impactSoft: return .soft
            default: return nil
            }
        }
        
        func toNotificationFeedbackType() -> UINotificationFeedbackGenerator.FeedbackType? {
            switch self {
            case .error: return .error
            case .success: return .success
            case .warning: return .warning
            default: return nil
            }
        }
    }
    
    static var supportsHaptics: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    /// Creates a feedback generator for the given style of feedback
    /// - Parameter style: The style of feedback to create a generator for
    func setup(for style: FeedbackStyle) {
        guard !generators.contains(where: { $0.supports(style) }) else {
            return
        }
        
        generators.append(UIFeedbackGenerator.make(supporting: style))
    }
    
    func setup(for styles: [FeedbackStyle]) {
        for style in styles {
            setup(for: style)
        }
    }
    
    /// Removes all feedback generators and frees up their resources
    func teardownAll() {
        generators.removeAll()
    }
    
    /// Removes any the generators which support the given style in order to free up their resources
    /// - Parameter style: The style of feedback generators to remove.
    func teardown(for style: FeedbackStyle) {
        generators.removeAll(where: { $0.supports(style) })
    }
    
    /// Prepares the generator for the given type of feedback. If a generator does not already
    /// exist, one will be created and then prepared.
    ///
    /// - Parameter style: The style of feedback to prepare to be generated.
    func prepare(for style: FeedbackStyle) {
        // Create the generator if it doesn't already exist
        setup(for: style)
        
        generators.first(where: { $0.supports(style) })?.prepare()
    }
    
    /// Triggers the appropriate feedback generator to generate feedback. If a generator does not
    /// already exist, one will not be created by this function. `setup(for:)` or `prepare(for:)`
    /// should be called first.
    ///
    /// - Parameters:
    ///   - style: Style of feedback to generate
    ///   - intensity: Optional parameter for impact-type styles. Ignored by all other styles
    func trigger(for style: FeedbackStyle, intensity: CGFloat? = nil) {
        guard let generator = generators.first(where: { $0.supports(style) }) else {
            return
        }
        
        switch style {
        case .impactHeavy, .impactLight, .impactMedium, .impactRigid, .impactSoft:
            guard let impactGenerator = generator as? ImpactFeedbackGeneratorWrapper else {
                return
            }
            
            if let intensity = intensity {
                impactGenerator.impactOccurred(intensity: intensity)
            } else {
                impactGenerator.impactOccurred()
            }
            
        case .selection:
            guard let selectionGenerator = generator as? UISelectionFeedbackGenerator else {
                return
            }
            
            selectionGenerator.selectionChanged()
            
        case .error, .success, .warning:
            guard let notificationGenerator = generator as? UINotificationFeedbackGenerator else {
                return
            }
            
            guard let type = style.toNotificationFeedbackType() else {
                return
            }
            
            notificationGenerator.notificationOccurred(type)
        }
    }
}

private class ImpactFeedbackGeneratorWrapper: UIImpactFeedbackGenerator {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    
    override init(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        self.style = style
        super.init(style: style)
    }
}

private extension UIFeedbackGenerator {
    func supports(_ style: HapticEngine.FeedbackStyle) -> Bool {
        switch style {
        case .impactHeavy, .impactLight, .impactMedium, .impactRigid, .impactSoft:
            guard let impact = self as? ImpactFeedbackGeneratorWrapper else {
                return false
            }
            
            return impact.style == style.toImpactFeedbackStyle()
            
        case .selection:
            return self is UISelectionFeedbackGenerator
            
        case .error, .success, .warning:
            return self is UINotificationFeedbackGenerator
        }
    }
    
    static func make(supporting style: HapticEngine.FeedbackStyle) -> UIFeedbackGenerator {
        switch style {
        case .impactHeavy, .impactLight, .impactMedium, .impactRigid, .impactSoft:
            guard let impactStyle = style.toImpactFeedbackStyle() else {
                return ImpactFeedbackGeneratorWrapper(style: .light)
            }
            
            return ImpactFeedbackGeneratorWrapper(style: impactStyle)
            
        case .selection:
            return UISelectionFeedbackGenerator()
            
        case .error, .success, .warning:
            return UINotificationFeedbackGenerator()
        }
    }
}
