//
//  WaypointAudioButton.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

struct WaypointAudioButton: View {
    
    @ScaledMetric(relativeTo: .body) private var animationSize: CGFloat = 18.0
    
    // MARK: Audio Player Management
    @StateObject private var audio: AudioFileStore = AudioFileStore()
    @Binding private var isPlayingAudio: AudioPlayerIdentifier?
    @State private var playerId: AudioPlayerIdentifier?
    
    // MARK: Audio Clip Details
    
    private let activityID: String
    private let remoteURL: URL
    private let description: String
    
    private let timeFormatter = DateComponentsFormatter()
    
    var elapsedLabel: String {
        return timeFormatter.string(from: audio.duration - audio.elapsed) ?? ""
    }
    
    var durationLabel: String {
        return timeFormatter.string(from: audio.duration) ?? ""
    }
    
    // MARK: Initialization
    
    init(isPlayingAudio: Binding<UUID?>, activityID: String, remoteURL: URL, description: String) {
        _isPlayingAudio = isPlayingAudio
        self.activityID = activityID
        self.remoteURL = remoteURL
        self.description = description
        timeFormatter.allowedUnits = [.minute, .second]
        timeFormatter.collapsesLargestUnit = false
        timeFormatter.zeroFormattingBehavior = .pad
    }
    
    // MARK: `body`
    
    var body: some View {
        Button {
            var isActivityActive = false
            
            if let tour = AppContext.shared.eventProcessor.activeBehavior as? GuidedTour, tour.content.id == activityID {
                isActivityActive = true
            }
            
            GDATelemetry.track("waypoint_detail.audio.toggle", with: ["isActivityActive": "\(isActivityActive)", "isPlaying": (!audio.isPlaying).description])
            
            toggleAudio()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12.0) {
                    if !audio.isDownloaded {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryForeground))
                            .frame(width: animationSize, height: animationSize, alignment: .center)
                            .accessibilityHidden(true)
                    } else if audio.isPlaying {
                        IsPlayingAnimation()
                            .frame(width: animationSize, height: animationSize, alignment: .center)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "play.circle")
                            .resizable()
                            .frame(width: animationSize, height: animationSize, alignment: .center)
                            .accessibilityHidden(true)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(description)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        
                        if !audio.isDownloaded {
                            GDLocalizedTextView("general.downloading")
                                .font(.caption)
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    if audio.isPlaying {
                        Text(elapsedLabel)
                            .font(.caption.monospacedDigit())
                            .accessibilityAddTraits(.updatesFrequently)
                    } else {
                        Text(durationLabel)
                            .font(.caption.monospacedDigit())
                    }
                }
                .padding(10)
                .padding([.top, .bottom], 4)
                
                if audio.isPlaying {
                    if #available(iOS 15.0, *) {
                        ProgressView(value: audio.elapsed, total: audio.duration)
                            .tint(Color.primaryForeground)
                            .background(Color.primaryBackground)
                            .accessibilityHidden(true)
                            .padding([.top], -4)
                    } else {
                        ProgressView(value: audio.elapsed, total: audio.duration)
                            .accessibilityHidden(true)
                            .padding([.top], -4)
                    }
                }
            }
            .roundedBackground(padding: 0, Color.black.opacity(0.2))
            .accessibilityElement(children: .combine)
            .accessibilityHint(GDLocalizedString(audio.isPlaying ? "general.stop" : "general.play"))
        }
        .accessibilityAddTraits(.startsMediaSession)
        .disabled(!audio.isDownloaded)
        .onAppear {
            audio.load(activityID: activityID, remoteURL: remoteURL)
        }
        .onDisappear {
            stopAudio()
        }
        .onChange(of: audio.isPlaying) { isPlaying in
            let oldPlayerId = playerId
            playerId = audio.playerID
            
            if isPlaying, let playerId = playerId {
                guard isPlayingAudio != playerId else {
                    // no-op
                    return
                }
                
                isPlayingAudio = playerId
            } else {
                guard isPlayingAudio == oldPlayerId else {
                    // no-op
                    return
                }
                
                isPlayingAudio = nil
            }
        }
    }
    
    // MARK: Audio
    
    private func toggleAudio() {
        if audio.isPlaying {
            // Stop audio
            stopAudio()
        } else {
            // Start audio
            startAudio()
        }
    }
    
    private func startAudio() {
        // If another player is currently playing, stop it before starting the new one
        if let currentPlayerID = isPlayingAudio {
            AppContext.shared.audioEngine.stop(currentPlayerID)
        }
        
        audio.start()
    }
    
    private func stopAudio() {
        guard audio.isPlaying else {
            return
        }
        
        audio.stop()
    }
    
}

struct WaypointAudioButton_Previews: PreviewProvider {
    
    static let audio1 = AudioDetail(url: URL(string: "www.bing.com")!, description: "This audio belongs to a waypoint")
    
    static let audio2 = AudioDetail(url: URL(string: "www.bing.com")!, description: "This is another audio clip for this waypoint.")
    
    static var previews: some View {
        VStack(spacing: 2.0) {
            WaypointAudioButton(isPlayingAudio: .constant(UUID()),
                                activityID: "",
                                remoteURL: URL(fileURLWithPath: ""),
                                description: audio1.description)
            WaypointAudioButton(isPlayingAudio: .constant(nil),
                                activityID: "",
                                remoteURL: URL(fileURLWithPath: ""),
                                description: audio2.description)
            WaypointAudioButton(isPlayingAudio: .constant(UUID()),
                                activityID: "",
                                remoteURL: URL(fileURLWithPath: ""),
                                description: "This is a really really really really really really really really really really really really really really really really long description")
        }
        .background(Color.primaryBackground)
        .foregroundColor(.primaryForeground)
    }
    
}
