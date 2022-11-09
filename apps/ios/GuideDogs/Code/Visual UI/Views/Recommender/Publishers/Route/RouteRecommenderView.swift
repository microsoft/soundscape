//
//  RouteRecommenderView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct RouteRecommenderView: View {
    
    // MARK: Properties
    
    @EnvironmentObject var navHelper: ViewNavigationHelper
    @State private var isTutorialActive: Bool = false
        
    let route: RouteDetail
    
    // MARK: Body
    
    var body: some View {
        Button(action: {
            if FirstUseExperience.didComplete(.routeTutorial) {
                let behavior = RouteGuidance(route,
                                             spatialData: AppContext.shared.spatialDataContext,
                                             motion: AppContext.shared.motionActivityContext)
                AppContext.shared.eventProcessor.activateCustom(behavior: behavior)
            } else {
                isTutorialActive = true
            }
        }, label: {
            RecommenderContainerView {
                VStack(alignment: .leading, spacing: 4.0) {
                    GDLocalizedTextView("route_detail.action.start_route")
                        .font(.body)
                    Text(route.displayName)
                        .font(.title3)
                    
                    NavigationLink(
                        destination: RouteTutorialView(detail: route, isShown: $isTutorialActive).environmentObject(navHelper),
                        isActive: $isTutorialActive,
                        label: {
                            EmptyView()
                        })
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .foregroundColor(Color.primaryForeground)
            .accessibleTextFormat()
        })
    }
    
}

struct RouteRecommenderView_Previews: PreviewProvider {

    static let route = RouteDetailsView_Previews.testOMRoute
    
    static var previews: some View {
        RouteRecommenderView(route: route)
            .environmentObject(ViewNavigationHelper())
            .padding(.horizontal, 18.0)
            .padding(.vertical, 12.0)
            .linearGradientBackground(.purple)
            .cornerRadius(10.0)
            .padding(24.0)
    }
    
}
