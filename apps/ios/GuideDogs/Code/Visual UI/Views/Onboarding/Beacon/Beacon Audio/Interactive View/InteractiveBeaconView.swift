//
//  InteractiveBeaconView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct InteractiveBeaconView: View {
    
    // MARK: Properties
    
    @ObservedObject private var viewModel = InteractiveBeaconViewModel()
    @State private var isAnimating = false
    @State private var didFirstCalloutComplete = false
    
    // MARK: `body`
    
    var body: some View {
        GeometryReader { geometry in
            let diameter = Double.minimum(geometry.size.width, geometry.size.height)
            
            ZStack(alignment: .center) {
                Image(systemName: "circle.fill")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.4)
                    .blur(radius: 50.0)
                    .foregroundColor(.black)
                
                Image("phone_pointer")
                    .resizable()
                    .frame(width: 80.0, height: 80.0)
                
                AudioSourceAnimation()
                    .foregroundColor(viewModel.isBeaconInBounds ? Color.greenHighlight : Color.secondaryForeground)
                    .frame(width: 48.0, height: 48.0)
                    .offset(y: -diameter / 2.0 + 48.0)
                    .animation(.easeIn)
                    .rotationEffect(.degrees(viewModel.bearingToBeacon))
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minWidth: 300.0, minHeight: 300.0)
        .onChange(of: viewModel.beaconOrientation) { newValue in
            guard didFirstCalloutComplete else {
                return
            }
            
            let event: SelectedBeaconOrientationCalloutEvent
            
            switch newValue {
            case .ahead:
                event = SelectedBeaconOrientationCalloutEvent(isAhead: true)
            case .behind:
                event = SelectedBeaconOrientationCalloutEvent(isAhead: false)
            case .other:
                // no-op
                return
            }
            
            AppContext.process(event)
        }
        .onAppear {
            // Start the animation
            isAnimating = true
            
            // Start the audio beacon
            AppContext.process(StartSelectedBeaconAudioEvent())
            
            // Include a delay so that the callout does not interrupt VoiceOver
            let delay = UIAccessibility.isVoiceOverRunning ? 2.5 : 1.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AppContext.process(SelectedBeaconCalloutEvent(completion: { (_) in
                    // After the callout completes, enable callouts triggered by changes in
                    // orientation
                    didFirstCalloutComplete = true
                }))
            }
        }
        .onDisappear {
            AppContext.process(StopSelectedBeaconAudioEvent())
        }
    }
    
}

struct InteractiveBeaconView_Previews: PreviewProvider {
    
    static var previews: some View {
        InteractiveBeaconView()
            .padding(24.0)
            .linearGradientBackground(.darkBlue, ignoresSafeArea: true)
        
        // Ensure sizing / spacing work well in a scroll view
        ScrollView {
            InteractiveBeaconView()
        }
        .linearGradientBackground(.darkBlue, ignoresSafeArea: true)
    }
    
}
