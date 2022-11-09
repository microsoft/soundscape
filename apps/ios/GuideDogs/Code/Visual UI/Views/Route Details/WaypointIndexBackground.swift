//
//  WaypointIndexBackground.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct WaypointIndexBackground: View {
    let state: WaypointCellGuidanceState
    
    @State var activeBorderColor: Color
    @State var opacity: Double = 0.0
    
    init(state: WaypointCellGuidanceState) {
        self.state = state
        
        // NOTE: This is a workaround for a Xcode 12.4 bug. From Xcode 12.5 on, this can be:
        //
        // self.activeBorderColor = state.strokeColors.0
        //
        // This should be updated as soon as ADO supports MacOS images running Xcode 12.5.
        
        self._activeBorderColor = State(initialValue: state.strokeColors.0)
    }
    
    private var fill: some View {
        Circle().fill(Color.secondaryBackground)
    }
    
    var body: some View {
        if state == .next {
            ZStack {
                Circle()
                    .strokeBorder(style: state.strokeStyles.0)
                    .foregroundColor(state.strokeColors.0)
                    .background(fill)
                
                Circle()
                    .strokeBorder(style: state.strokeStyles.1)
                    .opacity(opacity)
                    .foregroundColor(activeBorderColor)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            self.activeBorderColor = state.strokeColors.1
                            self.opacity = 1.0
                        }
                    }
            }
        } else {
            Circle()
                .strokeBorder(style: state.strokeStyles.1)
                .foregroundColor(state.strokeColors.0)
                .background(fill)
        }
    }
}
