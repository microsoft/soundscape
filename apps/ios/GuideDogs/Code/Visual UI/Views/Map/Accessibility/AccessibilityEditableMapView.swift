//
//  AccessibilityEditableMapView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct AccessibilityEditableMapView: View {
    
    var accessibilityHint: String {
        let key: String
        
        switch viewModel.direction {
        case .north: key = "location_detail.map.edit.north.accessibility_hint"
        case .south: key = "location_detail.map.edit.south.accessibility_hint"
        case .east: key = "location_detail.map.edit.east.accessibility_hint"
        case .west: key = "location_detail.map.edit.west.accessibility_hint"
        case .compass: key = "location_detail.map.edit.compass.accessibility_hint"
        }
        
        return GDLocalizedString(key)
    }
    
    // MARK: Properties
    
    @EnvironmentObject var viewModel: AccessibilityEditableMapViewModel
    
    private let detail: LocationDetail
    private let onChange: ((LocationDetail) -> Void)?
    
    // MARK: Initialization
    
    init(detail: LocationDetail, onChange: ((LocationDetail) -> Void)? = nil) {
        self.detail = detail
        self.onChange = onChange
    }
    
    // MARK: `body`
    
    var body: some View {
        Button {
            accessibilityEditLocationHandler()
        } label: {
            EmptyView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Accessibility label & hint
        .accessibilityLabel(GDLocalizedString("location_detail.map.edit.accessibility_label"))
        .accessibilityHint(accessibilityHint)
        // Add accessibility actions
        .accessibilityAction(named: GDLocalizedString("location_detail.map.edit.accessibility_action.north")) {
            // Update direction
            viewModel.direction = .north
            
            // Nudge north
            accessibilityEditLocationHandler()
        }
        .accessibilityAction(named: GDLocalizedString("location_detail.map.edit.accessibility_action.south")) {
            // Update direction
            viewModel.direction = .south
            
            // Nudge south
            accessibilityEditLocationHandler()
        }
        .accessibilityAction(named: GDLocalizedString("location_detail.map.edit.accessibility_action.east")) {
            // Update direction
            viewModel.direction = .east
            
            // Nudge east
            accessibilityEditLocationHandler()
        }
        .accessibilityAction(named: GDLocalizedString("location_detail.map.edit.accessibility_action.west")) {
            // Update direction
            viewModel.direction = .west
            
            // Nudge west
            accessibilityEditLocationHandler()
        }
        .accessibilityAction(named: GDLocalizedString("location_detail.map.edit.accessibility_action.compass")) {
            // Update direction
            viewModel.direction = .compass
            
            // Nudge in direction given by the phone's compass
            accessibilityEditLocationHandler()
        }
        .accessibilityAction(named: GDLocalizedString("location_detail.map.edit.accessibility_action.current_location")) {
            GDATelemetry.track("nudge_marker.current_location")
            
            guard let location = AppContext.shared.geolocationManager.location else {
                GDATelemetry.track("nudge_marker.current_location.location_nil")
                return
            }
            
            // Notify parent view
            self.onChange?(LocationDetail(location: location))
        }
    }
    
    // MARK: Handlers
    
    private func accessibilityEditLocationHandler() {
        GDATelemetry.track("nudge_marker", with: ["direction": viewModel.direction.rawValue])
        
        guard let degrees = viewModel.direction.degrees else {
            GDATelemetry.track("nudge_marker.direction_nil", with: ["direction": viewModel.direction.rawValue])
            return
        }
        
        // Move the selected location 5.0 meters in the given direction
        let newCoordinate = detail.location.coordinate.destination(distance: 5.0, bearing: degrees)
        let newLocation = LocationDetail(location: CLLocation(newCoordinate))
        
        // Notify parent view
        self.onChange?(newLocation)
    }
    
}

struct AccessibilityEditableMapView_Previews: PreviewProvider {
    
    static var locationDetail: LocationDetail {
        let location = CLLocation(latitude: 48.640179, longitude: -122.111320)
        
        let importedDetail = ImportedLocationDetail(nickname: "My Home", annotation: nil)
        
        return LocationDetail(location: location, imported: importedDetail, telemetryContext: nil)
    }
    
    static var previews: some View {
        AccessibilityEditableMapView(detail: locationDetail)
    }
    
}
