//
//  WaypointEditList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct WaypointEditList: View {
    
    // MARK: Properties
    
    @Binding private var identifiableWaypoints: [IdentifiableLocationDetail]
    
    // MARK: Initialization
    
    init(identifiableWaypoints: Binding<[IdentifiableLocationDetail]>) {
        _identifiableWaypoints = identifiableWaypoints
    }
    
    // MARK: `body`
    
    var body: some View {
        GDLocalizedTextView("route_detail.edit.waypoints_label")
            .frame(minWidth: 0.0, maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color.primaryForeground)
            .font(.callout)
            .plainListRowBackground(Color.secondaryBackground)
            .padding(.horizontal, 18.0)
            .padding(.vertical, 8.0)
            .accessibleTextFormat()
            .accessibilityAddTraits(.isHeader)
        
        ForEach(Array(identifiableWaypoints.enumerated()), id: \.0) { (index, element) in
            let userLocation = AppContext.shared.geolocationManager.location
            
            LocationItemView(locationDetail: element.locationDetail, userLocation: userLocation)
                .locationItemStyle(.editWaypoint(index: index))
                .accessibilityElement(children: .combine)
        }
        .onDelete(perform: { indexSet in
            identifiableWaypoints.remove(atOffsets: indexSet)
        })
        .onMove(perform: { indices, newOffset in
            identifiableWaypoints.move(fromOffsets: indices, toOffset: newOffset)
        })
    }
}

struct WaypointEditList_Previews: PreviewProvider {
    
    static var location: CLLocation {
        return CLLocation(latitude: 47.640179, longitude: -122.111320)
    }
    
    static var previews: some View {
        
        AppContext.shared.geolocationManager.mockLocation(CLLocation.sample)
        
        return List {
            WaypointEditList(identifiableWaypoints: .constant(RouteDetailsView_Previews.testOMRoute.waypoints.asIdenfifiable))
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(.active))
        .colorScheme(.dark)
        
    }
    
}
