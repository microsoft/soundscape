//
//  CustomScaledMetric.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  NOTE: This is a temporary replacement for the @ScaledMetric property wrapper
//  that is only available in iOS 14.0 and later. Remove this property wrapper when
//  the minimum supported iOS version increases to 14.0.
//

import SwiftUI

@propertyWrapper
struct CustomScaledMetric<Value>: DynamicProperty where Value: BinaryFloatingPoint {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.sizeCategory) var contentSize
    
    let textStyle: UIFont.TextStyle
    let baseValue: Value
    let maxValue: Value?
    
    // Creates the scaled metric with an unscaled value and a text style to scale relative to.
    init(wrappedValue: Value, maxValue: Value? = nil, relativeTo textStyle: Font.TextStyle = .body) {
        self.textStyle = textStyle.uiKit
        self.baseValue = wrappedValue
        self.maxValue = maxValue
    }
    
    private var traitCollection: UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(horizontalSizeClass: horizontalSizeClass?.uiKit ?? .unspecified),
            UITraitCollection(verticalSizeClass: verticalSizeClass?.uiKit ?? .unspecified),
            UITraitCollection(preferredContentSizeCategory: contentSize.uiKit)
        ])
    }
    
    // The value scaled based on the current environment.
    var wrappedValue: Value {
        let scaled = Value(UIFontMetrics(forTextStyle: textStyle).scaledValue(for: CGFloat(baseValue), compatibleWith: traitCollection))
        return maxValue.map { min($0, scaled) } ?? scaled
    }
}

fileprivate extension UserInterfaceSizeClass {
    var uiKit: UIUserInterfaceSizeClass {
        switch self {
        case .compact: return .compact
        case .regular: return .regular
        @unknown default: return .unspecified
        }
    }
}

fileprivate extension ContentSizeCategory {
    var uiKit: UIContentSizeCategory {
        switch self {
        case .accessibilityExtraExtraExtraLarge: return .accessibilityExtraExtraExtraLarge
        case .accessibilityExtraExtraLarge: return .accessibilityExtraExtraLarge
        case .accessibilityExtraLarge: return .accessibilityExtraLarge
        case .accessibilityLarge: return .accessibilityLarge
        case .accessibilityMedium: return .accessibilityMedium
        case .extraExtraExtraLarge: return .extraExtraExtraLarge
        case .extraExtraLarge: return .extraExtraLarge
        case .extraLarge: return .extraLarge
        case .extraSmall: return .extraSmall
        case .large: return .large
        case .medium: return .medium
        case .small: return .small
        @unknown default: return .unspecified
        }
    }
}

extension Font.TextStyle {
    fileprivate var uiKit: UIFont.TextStyle {
        switch self {
        case .body: return .body
        case .callout: return .callout
        case .caption: return .caption1
        case .caption2: return .caption2
        case .footnote: return .footnote
        case .headline: return .headline
        case .largeTitle: return .largeTitle
        case .subheadline: return .subheadline
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        @unknown default: return .body
        }
    }
    
    var pointSize: CGFloat {
        return UIFont.preferredFont(forTextStyle: self.uiKit).pointSize
    }
}
