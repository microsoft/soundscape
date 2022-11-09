//
//  AudioSourceAnimation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct AudioSourceAnimation: View {
    
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let diameter = Double.minimum(geometry.size.width, geometry.size.height) - 2.0
                let spacing = diameter / 6.0
                
                Circle()
                    .frame(width: diameter)
                    .opacity(isAnimating ? 0.1 : 0.0)
                    .blur(radius: 10.0)
                    .animation(.linear(duration: 0.75).repeatForever())
                
                ForEach((0...4), id: \.self) { index in
                    Circle()
                        .stroke(lineWidth: 1.0)
                        .frame(width: diameter - spacing * Double(4 - index))
                        .opacity(isAnimating ? 0.8 : 0.0)
                        .blur(radius: isAnimating ? 0.5 : 0.0)
                        .animation(.linear(duration: 0.75).repeatForever().delay(0.1 * Double(index)))
                }
                
                Circle()
                    .frame(width: diameter - spacing * 5.0)
                    .opacity(isAnimating ? 0.2 : 0.1)
                    .blur(radius: isAnimating ? 3.0 : 5.0)
                    .animation(.linear(duration: 0.75).repeatForever())
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
}

struct AudioSourceAnimation_Previews: PreviewProvider {
    
    static var previews: some View {
        AudioSourceAnimation()
            .frame(width: 64.0, height: 64.0)
            .foregroundColor(.white)
            .linearGradientBackground(.purple, ignoresSafeArea: true)
    }
    
}
