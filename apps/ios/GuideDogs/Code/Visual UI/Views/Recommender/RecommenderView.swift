//
//  RecommenderView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

struct RecommenderView: View {
    
    // MARK: Properties
    
    @EnvironmentObject var navHelper: ViewNavigationHelper
    @StateObject var viewModel: RecommenderViewModel
    
    // MARK: `body`
    
    var body: some View {
        if let content = viewModel.content {
            content()
                .fixedSize(horizontal: false, vertical: true)
        } else {
            EmptyView()
        }
    }
    
}

struct RecommenderView_Previews: PreviewProvider {
    
    private class Recommender_Previews: Recommender {
        
        var publisher: CurrentValueSubject<(() -> AnyView)?, Never>
        
        init(content: (() -> AnyView)?) {
            publisher = .init(content)
        }
        
    }
    
    // No recommender view
    private static let emptyRecommendation = Recommender_Previews(content: nil)
    
    // Route recommender view
    private static let route = RouteDetailsView_Previews.testOMRoute
    private static let routeRecommendation = Recommender_Previews(content: { AnyView(RouteRecommenderView(route: route)) })
    
    static var previews: some View {
        
        NavigationView {
            RecommenderView(viewModel: RecommenderViewModel(recommender: routeRecommendation))
                .environmentObject(ViewNavigationHelper())
                .cornerRadius(5.0)
                .padding(12.0)
        }
        
        NavigationView {
            // This should be an empty view because there is no
            // current recommendation
            RecommenderView(viewModel: RecommenderViewModel(recommender: emptyRecommendation))
                .environmentObject(ViewNavigationHelper())
                .cornerRadius(5.0)
                .padding(12.0)
        }
        
    }
    
}
