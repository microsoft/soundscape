//
//  UILocalizationSupport.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// This class adds support for localizing UI elements in Storyboard and XIB files.
// For supported objects, this adds an additional UI property called `localization`.
// This property should contain the key to the localization value from the main strings file.
// This should replace the need of having a separate strings file for every UI file.

private struct AssociatedObjectKey {
    static var textLocalization: UInt8 = 0
    static var accessibilityLabelLocalization: UInt8 = 0
    static var accessibilityHintLocalization: UInt8 = 0
    static var accessibilityValueLocalization: UInt8 = 0
}

// These properties dynamically store a localization value for objects
extension NSObject {
    fileprivate var textLocalization: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.textLocalization) as? String
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedObjectKey.textLocalization, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var accessibilityLabelLocalization: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.accessibilityLabelLocalization) as? String
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedObjectKey.accessibilityLabelLocalization, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var accessibilityHintLocalization: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.accessibilityHintLocalization) as? String
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedObjectKey.accessibilityHintLocalization, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var accessibilityValueLocalization: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.accessibilityValueLocalization) as? String
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedObjectKey.accessibilityValueLocalization, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension String {
    fileprivate var localized: String {
        return GDLocalizedString(self)
    }
}

protocol XIBLocalizable {
    var localization: String? { get set }
}

extension UILabel: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            text = newLocalizedValue
        }
    }
}

extension UIButton: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            setTitle(newLocalizedValue, for: .normal)
        }
    }
}

extension UINavigationItem: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            title = newLocalizedValue
        }
    }
}

extension UITextField: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            placeholder = newLocalizedValue
        }
    }
}

extension UITextView: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            text = newLocalizedValue
        }
    }
}

extension UIBarItem: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            title = newLocalizedValue
        }
    }
}

extension UISearchBar: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            placeholder = newLocalizedValue
        }
    }
}

extension UIViewController: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            textLocalization = newLocalizedValue
            title = newLocalizedValue
        }
    }
}

/// Segment titles should be seperated by `;`
extension UISegmentedControl: XIBLocalizable {
    @IBInspectable var localization: String? {
        get {
            return textLocalization
        }
        set {
            guard let newValue = newValue else { return }
            textLocalization = newValue

            let components = newValue.components(separatedBy: ";")
            guard !components.isEmpty else {
                return
            }
            
            for (segment, title) in components.enumerated() {
                setTitle(title.localized, forSegmentAt: segment)
            }
        }
    }
}

protocol XIBLocalizableAccessibility {
    var accLabelLocalization: String? { get set }
    var accHintLocalization: String? { get set }
    var accValueLocalization: String? { get set }
}

extension UIView: XIBLocalizableAccessibility {
    @IBInspectable var accLabelLocalization: String? {
        get {
            return accessibilityLabelLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            accessibilityLabelLocalization = newLocalizedValue
            accessibilityLabel = newLocalizedValue
        }
    }
    
    @IBInspectable var accHintLocalization: String? {
        get {
            return accessibilityHintLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            accessibilityHintLocalization = newLocalizedValue
            accessibilityHint = newLocalizedValue
        }
    }
    
    @IBInspectable var accValueLocalization: String? {
        get {
            return accessibilityValueLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            accessibilityValueLocalization = newLocalizedValue
            accessibilityValue = newValue?.localized
        }
    }
}

extension UIBarItem: XIBLocalizableAccessibility {
    @IBInspectable var accLabelLocalization: String? {
        get {
            return accessibilityLabelLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            accessibilityLabelLocalization = newLocalizedValue
            accessibilityLabel = newLocalizedValue
        }
    }
    
    @IBInspectable var accHintLocalization: String? {
        get {
            return accessibilityHintLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            accessibilityHintLocalization = newLocalizedValue
            accessibilityHint = newLocalizedValue
        }
    }
    
    @IBInspectable var accValueLocalization: String? {
        get {
            return accessibilityValueLocalization
        }
        set {
            let newLocalizedValue = newValue?.localized
            accessibilityValueLocalization = newLocalizedValue
            accessibilityValue = newLocalizedValue
        }
    }
}

protocol XIBLowerUpperCased {
    var lowercased: Bool { get set }
    var uppercased: Bool { get set }
}

extension UILabel: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set { if newValue { text = text?.lowercasedWithAppLocale() } }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set { if newValue { text = text?.uppercasedWithAppLocale() } }
    }
}

extension UIButton: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set {
            if let title = title(for: .normal), newValue {
                setTitle(title.lowercasedWithAppLocale(), for: .normal)
            }
        }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set {
            if let title = title(for: .normal), newValue {
                setTitle(title.uppercasedWithAppLocale(), for: .normal)
            }
        }
    }
}

extension UINavigationItem: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set { if newValue { title = title?.lowercasedWithAppLocale() } }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set { if newValue { title = title?.uppercasedWithAppLocale() } }
    }
}

extension UITextField: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set { if newValue { placeholder = placeholder?.lowercasedWithAppLocale() } }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set { if newValue { placeholder = placeholder?.uppercasedWithAppLocale() } }
    }
}

extension UITextView: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set { if newValue { text = text?.lowercasedWithAppLocale() } }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set { if newValue { text = text?.uppercasedWithAppLocale() } }
    }
}

extension UIBarItem: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set { if newValue { title = title?.lowercasedWithAppLocale() } }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set { if newValue { title = title?.uppercasedWithAppLocale() } }
    }
}

extension UISearchBar: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set { if newValue { placeholder = placeholder?.lowercasedWithAppLocale() } }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set { if newValue { placeholder = placeholder?.uppercasedWithAppLocale() } }
    }
}

/// Segment titles should be seperated by `;`
extension UISegmentedControl: XIBLowerUpperCased {
    @IBInspectable var lowercased: Bool {
        get { return false }
        set {
            guard newValue else {
                return
            }
            
            for i in 0..<numberOfSegments {
                let lowercased = titleForSegment(at: i)?.lowercasedWithAppLocale()
                setTitle(lowercased, forSegmentAt: i)
            }
        }
    }
    @IBInspectable var uppercased: Bool {
        get { return false }
        set {
            guard newValue else {
                return
            }
            
            for i in 0..<numberOfSegments {
                let uppercased = titleForSegment(at: i)?.uppercasedWithAppLocale()
                setTitle(uppercased, forSegmentAt: i)
            }
        }
    }
}
