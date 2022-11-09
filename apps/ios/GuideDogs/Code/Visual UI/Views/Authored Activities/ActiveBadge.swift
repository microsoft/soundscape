//
//  ActiveBadge.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct AnimatedBeaconIcon: View {
    @State private var radiusRatio: CGFloat = 0.3
    @State private var opacity: Double = 1.0
    
    let color: Color
    
    private let defaultRadiusRatio: CGFloat = 0.3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: geometry.size.width * defaultRadiusRatio,
                           height: geometry.size.height * defaultRadiusRatio,
                           alignment: .center)
                
                Circle()
                    .fill(color.opacity(opacity))
                    .frame(width: geometry.size.width * radiusRatio,
                           height: geometry.size.height * radiusRatio,
                           alignment: .center)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                self.radiusRatio = 1.0
                self.opacity = 0.0
            }
        }
    }
}

struct ActiveBadge: View {
    // NOTE: This temporary property wrapper should be replaced with @ScaledMetric when the
    //       minimum iOS supported version is increased to 14.0!
    @CustomScaledMetric(maxValue: 48.0, relativeTo: .subheadline) var iconSize: CGFloat = 24.0
    
    let color: Color
    
    init(_ color: Color = Color.yellowHighlight) {
        self.color = color
    }
    
    var body: some View {
        HStack(alignment: .center) {
            AnimatedBeaconIcon(color: color)
                .frame(width: iconSize, height: iconSize)
                
            Text(GDLocalizedString("behavior.experience.badges.active"))
                .font(.subheadline)
                .fontWeight(.light)
                .foregroundColor(color)
        }
    }
}

struct ActiveBadge_Previews: PreviewProvider {
    static var previews: some View {
        ActiveBadge()
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
        
        ActiveBadge()
            .environment(\.sizeCategory, .accessibilityMedium)
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
        
        ActiveBadge()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .padding([.all], 8.0)
            .background(Color.secondaryBackground)
            .previewLayout(.sizeThatFits)
    }
}
