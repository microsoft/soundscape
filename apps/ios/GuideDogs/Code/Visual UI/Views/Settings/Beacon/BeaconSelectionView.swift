//
//  BeaconSelectionView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct BeaconSelectionView: View {
    
    let beaconDemo = BeaconDemoHelper()
    
    @State var isPresented: Bool = false
    @State var selectedBeaconKey: String
    @State var areMelodiesEnabled: Bool
    
    let initialBeacon: String
    let initialMelodies: Bool
    
    init() {
        _selectedBeaconKey = State(initialValue: SettingsContext.shared.selectedBeacon)
        _areMelodiesEnabled = State(initialValue: SettingsContext.shared.playBeaconStartAndEndMelodies)
        initialBeacon = SettingsContext.shared.selectedBeacon
        initialMelodies = SettingsContext.shared.playBeaconStartAndEndMelodies
    }
    
    var body: some View {
        ZStack {
            Color.quaternaryBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        GDLocalizedTextView("beacon.settings.explanation")
                            .font(.caption)
                            .foregroundColor(.primaryForeground)
                            .padding([.leading, .trailing, .top])
                        
                        Spacer()
                    }
                    
                    TableHeaderCell(text: GDLocalizedString("beacon.settings.cues"))
                        .accessibility(hidden: true)
                    
                    Toggle(GDLocalizedString("beacon.settings.melodies"), isOn: $areMelodiesEnabled)
                        .locationNameTextFormat()
                        .padding()
                        .background(Color.primaryBackground)
                        .onChange(of: areMelodiesEnabled, perform: { _ in
                            SettingsContext.shared.playBeaconStartAndEndMelodies = areMelodiesEnabled
                            beaconDemo.play(styleChanged: true)
                        })
                    
                    TableHeaderCell(text: GDLocalizedString("beacon.settings.style"))
                    
                    ForEach(BeaconOption.allAvailableCases(for: .standard)) { details in
                        BeaconOptionCell(type: details.id,
                                         displayName: details.localizedName,
                                         selectedType: $selectedBeaconKey) {
                            beaconDemo.play(styleChanged: true, shouldTimeOut: false)
                        }
                    }
                    
                    if let beacons = BeaconOption.allAvailableCases(for: .haptic), !beacons.isEmpty {
                        TableHeaderCell(text: GDLocalizedString("beacon.settings.style.haptic"))
                        
                        HStack(spacing: 0) {
                            GDLocalizedTextView("beacon.settings.style.haptic.explanation")
                                .font(.caption)
                                .foregroundColor(.primaryForeground)
                                .padding()
                            
                            Spacer()
                        }
                        
                        ForEach(beacons) { details in
                            BeaconOptionCell(type: details.id,
                                             displayName: details.localizedName,
                                             selectedType: $selectedBeaconKey) {
                                beaconDemo.play(styleChanged: true, shouldTimeOut: false)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(GDLocalizedString("beacon.settings_title"))
        .onAppear {
            beaconDemo.prepare(disableMelodies: false)
            
            GDATelemetry.trackScreenView("beacon_settings")
            
            isPresented = true
        }
        .onDisappear(perform: {
            if SettingsContext.shared.selectedBeacon != initialBeacon {
                let props = [
                    "from": initialBeacon,
                    "to": selectedBeaconKey
                ]
                
                GDATelemetry.track("beacon.style_changed", with: props)
            }
            
            if SettingsContext.shared.playBeaconStartAndEndMelodies != initialMelodies {
                if initialMelodies {
                    GDATelemetry.track("beacon.melodiesDisabled")
                } else {
                    GDATelemetry.track("beacon.melodiesEnabled")
                }
            }
            
            beaconDemo.restoreState()
            
            isPresented = false
        })
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard isPresented else {
                return
            }
            
            beaconDemo.prepare(disableMelodies: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            guard isPresented else {
                return
            }
            
            beaconDemo.restoreState()
        }
    }
}

struct BeaconSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BeaconSelectionView()
            
    }
}
