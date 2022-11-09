//
//  CompletionBadge.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct CompletionBadge: View {
    // NOTE: This temporary property wrapper should be replaced with @ScaledMetric when the
    //       minimum iOS supported version is increased to 14.0!
    @CustomScaledMetric(maxValue: 48.0, relativeTo: .subheadline) var iconSize: CGFloat = 20.0
    
    @Environment(\.sizeCategory) var sizeCategory
    
    let isComplete: Bool
    let foregroundColor: Color
    let backgroundColor: Color
    
    init(_ isComplete: Bool, foreground: Color = Color.yellow, background: Color = Color.black) {
        self.isComplete = isComplete
        self.foregroundColor = foreground
        self.backgroundColor = background
    }
    
    var body: some View {
        if isComplete {
            HStack(alignment: .center) {
                Circle()
                    .fill(foregroundColor)
                    .overlay(
                        Star(corners: 5, smoothness: 2.0 / (sqrt(5) + 3.0))
                            .fill(backgroundColor)
                            .aspectRatio(contentMode: .fit)
                            .padding([.all], 3)
                    )
                    .frame(width: iconSize, height: iconSize)
                
                Text(GDLocalizedString("behavior.experience.badges.complete"))
                    .font(.subheadline)
                    .fontWeight(.light)
                    .foregroundColor(foregroundColor)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            HStack(alignment: .center) {
                Circle()
                    .fill(Color.gray)
                    .frame(width: iconSize * 0.8, height: iconSize * 0.8)
                
                Text(GDLocalizedString("behavior.experience.badges.not_complete"))
                    .font(.subheadline)
                    .fontWeight(.light)
                    .foregroundColor(Color.gray)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CompletionBadge_Previews: PreviewProvider {
    static var previews: some View {
        CompletionBadge(true)
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Completed State")
        
        CompletionBadge(false)
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Not Completed State")
        
        CompletionBadge(true)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Completed State")
        
        CompletionBadge(false)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Not Completed State")
    }
}
