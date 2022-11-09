//
//  WaypointAudioView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct WaypointAudioView: View {
    
    // MARK: Properties
    
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 64.0
    @State private var isPlayingAudio: UUID?
    @State private var calloutsEnabledDefault: Bool = true
    
    let activityID: String
    let allAudio: [ActivityWaypointAudioClip]
    
    // MARK: `body`
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4.0) {
                ForEach(allAudio) { audio in
                    HStack(spacing: 8.0) {
                        WaypointAudioButton(isPlayingAudio: $isPlayingAudio,
                                            activityID: activityID,
                                            remoteURL: audio.url,
                                            description: audio.description ?? "")
                            .shadow(radius: 5.0)
                    }
                    .padding(.horizontal, 4.0)
                }
            }
            .padding(.vertical, 8.0)
        }
        .onAppear {
            calloutsEnabledDefault = SettingsContext.shared.automaticCalloutsEnabled
        }
        .onDisappear {
            SettingsContext.shared.automaticCalloutsEnabled = calloutsEnabledDefault
        }
        .onChange(of: isPlayingAudio) { _ in
            guard calloutsEnabledDefault else {
                return
            }
            
            // When waypoint audio clips are playing, prevent additional callouts from occurring
            if isPlayingAudio != nil {
                SettingsContext.shared.automaticCalloutsEnabled = false
            } else {
                SettingsContext.shared.automaticCalloutsEnabled = true
            }
        }
    }
    
}

struct WaypointAudioView_Previews: PreviewProvider {
    
    static let audio = [
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This audio belongs to a waypoint"),
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This is another audio clip for this waypoint."),
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This audio also belongs to a waypoint. This audio has a really really really really really really really really really really really really really really really really really really really long description so that I can test the multiline layout.")
    ]
    
    static var previews: some View {
        VStack(spacing: 8.0) {
            WaypointAudioView(activityID: "testactivity", allAudio: audio)
                .frame(maxHeight: 88.0)
                .background(Color.Theme.blue)
                .foregroundColor(.white)
        }
        .frame(maxHeight: .infinity)
        .background(Color.Theme.darkBlue.ignoresSafeArea())
    }
    
}
