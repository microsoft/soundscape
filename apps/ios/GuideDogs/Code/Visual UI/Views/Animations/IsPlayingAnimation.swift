//
//  IsPlayingAnimation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct IsPlayingAnimation: View {
    
    // MARK: Properties
    
    @State private var isAnimating = false
    
    private let range = 1...4
    private let spacing = 2.0
    
    // MARK: `body`
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(range, id: \.self) { _ in
                    // Draw rectangles to fill the width of
                    // their container
                    // Account for spacing in between each rectangle
                    let width = ( geometry.size.width -  Double(range.upperBound) * spacing ) / Double(range.upperBound)
                    
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: width, height: geometry.size.height)
                        
                        if #available(iOS 15.0, *) {
                            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                                Rectangle()
                                    .frame(width: width, height: Double.random(in: 0...geometry.size.height))
                                    .animation(.linear)
                            }
                        } else {
                            let h1 = Double.random(in: 0...geometry.size.height)
                            let h2 = Double.random(in: 0...geometry.size.height)
                            
                            Rectangle()
                                .frame(width: width, height: isAnimating ? h2 : h1)
                                .animation(.linear.repeatForever())
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            isAnimating = true
        }
    }
    
}

struct IsPlayingAnimation_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            IsPlayingAnimation()
                .frame(width: 24.0, height: 24.0)
            
            // Try a larger size
            IsPlayingAnimation()
                .frame(width: 36.0, height: 36.0)
            
            // Try a non-square frame
            IsPlayingAnimation()
                .frame(width: 24.0, height: 36.0)
            
            // Try a non-square frame
            IsPlayingAnimation()
                .frame(width: 36.0, height: 24.0)
        }
        .foregroundColor(.white)
        .linearGradientBackground(.purple, ignoresSafeArea: true)
    }
    
}
