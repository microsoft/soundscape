//
//  AccessibilityHStack.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct AccessibilityHStack<Content: View>: View {
    
    // MARK: Properties
    
    @Environment(\.sizeCategory) var sizeCategory
    
    private let veritcalAlignment: VerticalAlignment
    private let horizontalAlignment: HorizontalAlignment
    private let spacing: CGFloat?
    private let content: () -> Content
    
    // MARK: Initialization
    
    init(verticalAlignment: VerticalAlignment = .center, horizontalAlignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.veritcalAlignment = verticalAlignment
        self.horizontalAlignment = horizontalAlignment
        self.spacing = spacing
        self.content = content
    }
    
    // MARK: `body`
    
    var body: some View {
        if sizeCategory.isAccessibilityCategory {
            VStack(alignment: horizontalAlignment, spacing: spacing) { content() }
                .fixedSize(horizontal: false, vertical: true)
        } else {
            HStack(alignment: veritcalAlignment, spacing: spacing) { content() }
        }
    }
    
}

struct AccessibilityHStack_Previews: PreviewProvider {
    
    static var previews: some View {
        AccessibilityHStack {
            Text("Hello World")
            Text("Hello World")
        }
        
        AccessibilityHStack {
            Text("Hello World")
            Text("Hello World")
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
}
