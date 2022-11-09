//
//  LocationItemView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct LocationItemView: View {
    
    // MARK: Properties
    
    @ScaledMetric(relativeTo: .body) private var accessorySize: CGFloat = 28.0
    
    private let locationDetail: LocationDetail
    private let userLocation: CLLocation?
    
    // Style configuration
    private let configuration: AnyLocationItemStyleConfiguration
    
    private var accessibilitySortPriority: LocationItemViewAccessibilitySortPriority {
        return configuration.customAccessibilitySortPriority ?? LocationItemViewAccessibilitySortPriority.defaultSortPriority
    }
    
    // MARK: Initialization
    
    init(locationDetail: LocationDetail, userLocation: CLLocation?) {
        self.locationDetail = locationDetail
        self.userLocation = userLocation
        // Use default style configuration
        self.configuration = LocationItemStyle.plain.configuration
        
        if let customAccessorySize = configuration.customAccessorySize {
            _accessorySize = .init(wrappedValue: customAccessorySize)
        }
    }
    
    private init(locationDetail: LocationDetail, userLocation: CLLocation?, style: LocationItemStyle = .plain) {
        self.locationDetail = locationDetail
        self.userLocation = userLocation
        self.configuration = style.configuration
        
        if let customAccessorySize = configuration.customAccessorySize {
            _accessorySize = .init(wrappedValue: customAccessorySize)
        }
    }
    
    // MARK: `body`
    
    var body: some View {
        HStack(spacing: 12.0) {
            configuration.rightAccessory
                .frame(width: accessorySize, height: accessorySize, alignment: .center)
                .accessibilitySortPriority(accessibilitySortPriority.rightAccessory)
            
            VStack(alignment: .leading, spacing: 2.0) {
                locationDetail.labels.name(isVerbose: false).accessibleTextView
                    .locationNameTextFormat()
                    .accessibilitySortPriority(accessibilitySortPriority.name)
                
                if let distance = locationDetail.labels.distance(from: userLocation) {
                    distance.accessibleTextView
                        .locationDistanceTextFormat()
                        .accessibilitySortPriority(accessibilitySortPriority.distance)
                }
                
                locationDetail.labels.address.accessibleTextView
                    .locationAddressTextFormat()
                    .accessibilitySortPriority(accessibilitySortPriority.address)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            configuration.leftAccessory
                .frame(width: accessorySize, height: accessorySize, alignment: .center)
                .accessibilitySortPriority(accessibilitySortPriority.leftAccessory)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12.0)
        .padding(.vertical, 8.0)
        .accessibilityElement(children: .combine)
        .ifLet(configuration.accessibilityHint, transform: { return $0.accessibilityHint(Text($1)) })
        .background(configuration.backgroundColor)
        // Applied when this view is used as an element in a list
        .plainListRowBackground(configuration.backgroundColor)
        .ifLet(configuration.customAccessibilityTraits, transform: { $0.accessibilityAddTraits($1) })
    }
    
}

struct LocationItemView_Previews: PreviewProvider {
    
    static var locationDetail: LocationDetail {
        let location = CLLocation(latitude: 48.640179, longitude: -122.111320)
        
        let importedDetail = ImportedLocationDetail(nickname: "My Home", annotation: nil)
        
        return LocationDetail(location: location, imported: importedDetail, telemetryContext: nil)
    }
    
    static var userLocation: CLLocation {
        return CLLocation(latitude: 47.640179, longitude: -122.111320)
    }
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 1.0) {
                LocationItemView(locationDetail: locationDetail, userLocation: userLocation)
                
                LocationItemView(locationDetail: locationDetail, userLocation: userLocation)
                    .locationItemStyle(.inset)
                
                LocationItemView(locationDetail: locationDetail, userLocation: userLocation)
                    .locationItemStyle(.addWaypoint(index: nil))
                
                LocationItemView(locationDetail: locationDetail, userLocation: userLocation)
                    .locationItemStyle(.addWaypoint(index: 10))
            }
        }
    }
    
}

extension LocationItemView {
    
    func locationItemStyle(_ style: LocationItemStyle) -> some View {
        LocationItemView(locationDetail: self.locationDetail, userLocation: self.userLocation, style: style)
    }
    
}

private struct ConditionalAccessibilitySortPriority: ViewModifier {
    
    let priority: Double?
    
    func body(content: Content) -> some View {
        content
            .ifLet(priority, transform: { $0.accessibilitySortPriority($1) })
    }
    
}

private extension View {
    
    func conditionalAccessibilitySortPriority(_ priority: Double?) -> some View {
        modifier(ConditionalAccessibilitySortPriority(priority: priority))
    }
    
}
