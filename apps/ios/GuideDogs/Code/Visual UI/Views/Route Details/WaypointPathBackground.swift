//
//  WaypointPathBackground.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct WaypointPathBackground: View {
    let state: WaypointCellGuidanceState
    let style: WaypointCellDisplayStyle
    
    init(state: WaypointCellGuidanceState, style: WaypointCellDisplayStyle) {
        self.state = state
        self.style = style
    }
    
    var body: some View {
        GeometryReader { geometry in
            let dashSpace = state.strokeStyles.0.dash.last ?? 0
            
            SwiftUI.Path { path in
                // Draw the path above the number bubble
                if style == .mid || style == .last {
                    path.move(to: CGPoint(x: geometry.size.width / 2.0, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0 - dashSpace))
                }
            }
            .strokedPath(state.strokeStyles.0)
            .foregroundColor(state.strokeColors.0)
            
            SwiftUI.Path { path in
                // Draw the path below the number bubble
                if style == .first || style == .mid {
                    path.move(to: CGPoint(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0))
                    path.addLine(to: CGPoint(x: geometry.size.width / 2.0, y: geometry.size.height))
                }
            }
            .strokedPath(state.strokeStyles.2)
            .foregroundColor(state.strokeColors.2)
        }
    }
}
