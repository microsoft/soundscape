//
//  Star.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct Star: Shape {
    /// Number of points on the star
    let corners: Int
    
    /// Ratio of the inner radius to the outer radius for the star
    let smoothness: CGFloat

    func path(in rect: CGRect) -> SwiftUI.Path {
        guard corners >= 3 else { return SwiftUI.Path() }

        let outerRadius = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let innerRadius = CGPoint(x: outerRadius.x * smoothness, y: outerRadius.y * smoothness)
        let angleIncrement = CGFloat.pi * 2 / CGFloat(corners * 2)
        var currentAngle = -CGFloat.pi / 2

        var path = SwiftUI.Path()
        path.move(to: CGPoint(x: outerRadius.x * cos(currentAngle) + rect.midX,
                              y: outerRadius.y * sin(currentAngle) + rect.midY))

        var maxY: CGFloat = 0.0
        for corner in 0 ..< corners * 2 {
            // Figure out if we are drawing an inner or outer vertex
            let point = corner.isMultiple(of: 2) ? outerRadius : innerRadius

            // Draw the vertex
            let vertexY = point.y * sin(currentAngle) + rect.midY
            path.addLine(to: CGPoint(x: point.x * cos(currentAngle) + rect.midX, y: vertexY))

            maxY = max(maxY, vertexY)
            
            // Move on to the next corner
            currentAngle += angleIncrement
        }
        
        let offset = (rect.height - maxY) / 2

        return path.applying(CGAffineTransform(translationX: 0.0, y: offset))
    }
}

struct Star_Previews: PreviewProvider {
    static var previews: some View {
        Star(corners: 5, smoothness: 2.0 / (sqrt(5) + 3.0))
            .fill(Color.black)
            .frame(width: 100, height: 100)
            .previewLayout(.sizeThatFits)
    }
}
