//
//  RouteTutorialView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct RouteTutorialView: View {
    
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    let detail: RouteDetail
    
    @Binding var isShown: Bool
    
    private func startGuidance(_ guidance: RouteGuidance) {
        if AppContext.shared.eventProcessor.isCustomBehaviorActive {
            AppContext.shared.eventProcessor.deactivateCustom()
        }
        
        // Try to make VoiceOver focus on the beacon panel after we pop to the home view controller
        if let home = navHelper.host?.navigationController?.viewControllers.first as? HomeViewController {
            home.shouldFocusOnBeacon = true
        }
        
        AppContext.shared.eventProcessor.activateCustom(behavior: guidance)
        navHelper.popToRootViewController(animated: true)
    }
    
    var body: some View {
        ZStack {
            Color
                .primaryBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack {
                        GDLocalizedTextView("routes.tutorial.title")
                            .foregroundColor(.primaryForeground)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits([.isHeader])
                            .padding()
                        
                        Image("destination_graphic03")
                            .resizable()
                            .scaledToFit()
                            .accessibilityHidden(true)
                        
                        GDLocalizedTextView("routes.tutorial.details")
                            .locationNameTextFormat()
                            .multilineTextAlignment(.center)
                            .padding([.leading, .trailing], 20)
                            .padding([.top, .bottom])
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button {
                        // Start the route and pop to the home screen
                        startGuidance(RouteGuidance(detail,
                                                    spatialData: AppContext.shared.spatialDataContext,
                                                    motion: AppContext.shared.motionActivityContext))
                        FirstUseExperience.setDidComplete(for: .routeTutorial)
                    } label: {
                        GDLocalizedTextView("general.alert.dismiss")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 48.0)
                            .padding(.vertical, 10.0)
                            .background(Color.primaryForeground)
                            .foregroundColor(Color.primaryBackground)
                            .cornerRadius(5.0)
                    }

                    Spacer()
                }
                .foregroundColor(.secondaryForeground)
                .padding([.leading, .trailing], 24)
                .padding([.top, .bottom])
            }
        }
    }
}

struct RouteTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        RouteTutorialView(detail: RouteDetail(source: .database(id: Route.sample.id)), isShown: .constant(true))
    }
}
