//
//  LocationDetailHeaderView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation
import RealmSwift

struct LocationDetailLabelView: View {
    
    // MARK: Properties
    
    @State private var location: LocationDetail
    
    let userLocation: CLLocation?
    private let titleColor: Color?
    private let subtitleColor: Color?
    private let highlightColor: Color?
    
    // MARK: Initialization
    
    init(location: LocationDetail, userLocation: CLLocation?) {
        self._location = State(initialValue: location)
        self.userLocation = userLocation
        // Use default values
        self.titleColor = nil
        self.subtitleColor = nil
        self.highlightColor = nil
    }
    
    private init(location: LocationDetail, userLocation: CLLocation?, titleColor: Color?, subtitleColor: Color?, highlightColor: Color?) {
        self._location = State(initialValue: location)
        self.userLocation = userLocation
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.highlightColor = highlightColor
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            VStack(alignment: .leading, spacing: 24.0) {
                location.labels.name().accessibleTextView
                    .foregroundColor(titleColor)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4.0) {
                    if let distance = location.labels.distance(from: userLocation) {
                        distance.accessibleTextView(leftAccessory: Image(systemName: "map"))
                            .font(.callout)
                            .foregroundColor(highlightColor)
                    }
                    
                    location.labels.address.accessibleTextView
                        .font(.callout)
                }
            }
            .accessibilityElement(children: .combine)
            
            if location.isMarker || location.annotation != nil {
                TitledText(title: GDLocalizedString("markers.annotation"), text: location.labels.annotation.text)
                    .foregroundColor(titleColor)
            }
            
            if let departureCallout = location.labels.departureCallout {
                TitledText(title: GDLocalizedString("callouts.departure"), text: departureCallout.text)
                    .foregroundColor(titleColor)
            }
            
            if let arrivalCallout = location.labels.arrivalCallout {
                TitledText(title: GDLocalizedString("callouts.arrival"), text: arrivalCallout.text)
                    .foregroundColor(titleColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Text modifiers
        .foregroundColor(subtitleColor)
        .font(.body)
        .accessibleTextFormat()
        .onAppear {
            guard !self.location.hasName || !self.location.hasAddress else {
                // Name and address are already known
                return
            }
            
            LocationDetail.fetchNameAndAddressIfNeeded(for: location) { detail in
                self.location = detail
            }
        }
    }
    
}

struct LocationDetailLabelView_Previews: PreviewProvider {
    
    static var location1: LocationDetail {
        let location = CLLocation(latitude: 48.640179, longitude: -122.111320)
        
        let importedDetail = ImportedLocationDetail(nickname: "My Home",
                                                    annotation: "An Annotation that is really really really really really really really really really long so that it takes up more than one line in the preview",
                                                    departure: "You are now departing a location",
                                                    arrival: "You are know arriving a location")
        return LocationDetail(location: location, imported: importedDetail)
    }
    
    static var location2: LocationDetail {
        let location = CLLocation(latitude: 48.640179, longitude: -122.111320)
        
        return LocationDetail(location: location)
    }
    
    static var userLocation: CLLocation {
        return CLLocation(latitude: 47.640179, longitude: -122.111320)
    }
    
    static var previews: some View {
        
        VStack(spacing: 0.0) {
            LocationDetailLabelView(location: location1, userLocation: userLocation)
                .titleColor(.white)
                .subtitleColor(Color.Theme.lightBlue)
                .highlightColor(Color.Theme.yellow)
                .padding(24.0)
                .background(Color.Theme.darkBlue)
            
            LocationDetailLabelView(location: location2, userLocation: userLocation)
                .titleColor(.white)
                .subtitleColor(Color.Theme.lightTeal)
                .highlightColor(Color.Theme.yellow)
                .padding(24.0)
                .background(Color.Theme.darkTeal)
        }
        
    }
    
}

extension LocationDetailLabelView {
    
    func titleColor(_ titleColor: Color) -> LocationDetailLabelView {
        LocationDetailLabelView(location: self.location, userLocation: self.userLocation, titleColor: titleColor, subtitleColor: self.subtitleColor, highlightColor: self.highlightColor)
    }
    
    func subtitleColor(_ subtitleColor: Color) -> LocationDetailLabelView {
        LocationDetailLabelView(location: self.location, userLocation: self.userLocation, titleColor: self.titleColor, subtitleColor: subtitleColor, highlightColor: self.highlightColor)
    }
    
    func highlightColor(_ highlightColor: Color) -> LocationDetailLabelView {
        LocationDetailLabelView(location: self.location, userLocation: self.userLocation, titleColor: self.titleColor, subtitleColor: self.subtitleColor, highlightColor: highlightColor)
    }
    
}
