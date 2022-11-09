//
//  RouteEditTutorialView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct RouteEditTutorialView: View {
    
    // MARK: `body`
    
    var body: some View {
        VStack(alignment: .center, spacing: 18.0) {
            GDLocalizedTextView("route.no_waypoints.hint.1")
            GDLocalizedTextView("route.no_waypoints.hint.2")
        }
        .font(.body)
        .foregroundColor(Color.primaryForeground)
        .multilineTextAlignment(.center)
        .accessibleTextFormat()
        .accessibilityElement(children: .combine)
        .frame(minHeight: 0.0, maxHeight: .infinity)
    }
    
}

struct RouteEditTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        RouteEditTutorialView()
            .background(Color.tertiaryBackground)
    }
}
