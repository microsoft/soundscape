//
//  EmptyMarkerOrRoutesList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct EmptyMarkerOrRoutesView: View {
    enum DisplayStyle {
        case markers
        case routes
    }
    
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 64.0
    
    let style: DisplayStyle
    
    init(_ style: DisplayStyle = .markers) {
        self.style = style
    }

    var localizedTitle: String {
        if style == .markers {
            return GDLocalizedString("markers.no_markers.title")
        } else {
            return GDLocalizedString("routes.no_routes.title")
        }
    }
    
    var localizedP1: String {
        if style == .markers {
            return GDLocalizedString("markers.no_markers.hint.1")
        } else {
            return GDLocalizedString("routes.no_routes.hint.1")
        }
    }
    
    var localizedP2: String {
        if style == .markers {
            return GDLocalizedString("markers.no_markers.hint.2")
        } else {
            return GDLocalizedString("routes.no_routes.hint.2")
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                
                if style == .markers {
                    Image("marker.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.primaryForeground)
                        .frame(width: iconSize, height: iconSize)
                } else {
                    Image("route.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.primaryForeground)
                        .frame(width: iconSize, height: iconSize)
                }
                
                Spacer()
            }
            .accessibilityHidden(true)
            
            Text(localizedTitle)
                .multilineTextAlignment(.center)
                .font(.title)
                .lineLimit(nil)
                .foregroundColor(.primaryForeground)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(addTraits: .isHeader)
                .padding([.top, .bottom], 16.0)
            
            Text(localizedP1)
                .multilineTextAlignment(.center)
                .font(.body)
                .lineLimit(nil)
                .foregroundColor(.primaryForeground)
                .padding([.bottom])
            
            Text(localizedP2)
                .multilineTextAlignment(.center)
                .font(.body)
                .lineLimit(nil)
                .foregroundColor(.primaryForeground)
        }
        .padding([.leading, .trailing], 32.0)
        .padding([.top, .bottom], 64.0)
    }
}

struct EmptyMarkerOrRoutesList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyMarkerOrRoutesView(.markers)
                .background(Color.quaternaryBackground)
            EmptyMarkerOrRoutesView(.routes)
                .background(Color.quaternaryBackground)
        }
    }
}
