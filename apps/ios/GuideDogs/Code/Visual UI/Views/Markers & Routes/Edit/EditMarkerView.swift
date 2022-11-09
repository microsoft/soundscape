//
//  EditMarkerView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine
import CoreLocation

struct EditMarkerConfig {
    let detail: LocationDetail
    let route: String?
    let context: String?
    let addOrUpdateAction: NavigationAction
    let deleteAction: NavigationAction?
    let cancelAction: NavigationAction?
    let leftBarButtonItemIsHidden: Bool
    let onLocationDidUpdate: ((LocationDetail) -> Void)?
    
    init(detail: LocationDetail,
         route: String? = nil,
         context: String? = nil,
         addOrUpdateAction: NavigationAction = .popViewController,
         deleteAction: NavigationAction?  = nil,
         cancelAction: NavigationAction? = nil,
         leftBarButtonItemIsHidden: Bool = false,
         onLocationDidUpdate: ((LocationDetail) -> Void)? = nil) {
        self.detail = detail
        self.route = route
        self.context = context
        self.cancelAction = cancelAction
        self.addOrUpdateAction = addOrUpdateAction
        self.deleteAction = deleteAction
        self.leftBarButtonItemIsHidden = leftBarButtonItemIsHidden
        self.onLocationDidUpdate = onLocationDidUpdate
    }
}

struct EditMarkerView: View {
    private enum EditViewAlert {
        case delete, saveError
    }
    
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    @CustomScaledMetric(maxValue: 26.0, relativeTo: .body) var fontSize: CGFloat = Font.TextStyle.body.pointSize
    
    let config: EditMarkerConfig
    private let beaconDemo = BeaconDemoHelper()
    
    @State var locationDetail: LocationDetail
    @State var updatedLocation: LocationDetail?
    
    @State private var isPlayingBeacon = false
    @State private var isFetchingNameAndAddress = false
    @State private var displayName: String
    @State private var displayAnnotation: String
    @State private var displayAddress: String
    @ObservedObject private var accessibilityEditableMapViewModel = AccessibilityEditableMapViewModel()
    
    @State private var alert: EditViewAlert?
    @State private var showAlert: Bool = false
    
    private var deleteIsEnabled: Bool {
        // Delete is enabled when editing an existing marker
        // and when supported by the delegate
        return locationDetail.isMarker && config.deleteAction != nil
    }
    
    init(config: EditMarkerConfig) {
        _locationDetail = State(initialValue: config.detail)
        self.config = config
        
        // Initialize editable text fields
        _displayName = State(initialValue: config.detail.displayName)
        _displayAddress = State(initialValue: config.detail.displayAddress)
        _displayAnnotation = State(initialValue: config.detail.annotation ?? "")
    }
    
    private var alertView: Alert {
        switch alert {
        case .delete:
            guard let markerId = locationDetail.markerId else {
                return Alert(title: GDLocalizedTextView("general.error.error_occurred"),
                             message: GDLocalizedTextView("markers.action.update_error"),
                             dismissButton: .default(GDLocalizedTextView("general.alert.dismiss")))
            }
            
            return Alert.deleteMarkerAlert(markerId: markerId, deleteAction: { delete() })
        default:
            return Alert(title: GDLocalizedTextView("general.error.error_occurred"),
                         message: GDLocalizedTextView("markers.action.update_error"),
                         dismissButton: .default(GDLocalizedTextView("general.alert.dismiss")))
        }
    }
    
    private var title: Text {
        if locationDetail.isMarker {
            return GDLocalizedTextView("markers.edit_screen.title.edit")
        } else {
            return GDLocalizedTextView("markers.edit_screen.title.save")
        }
    }
    
    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !config.leftBarButtonItemIsHidden {
                Button(GDLocalizedString("general.alert.cancel")) {
                    navHelper.onNavigationAction(config.cancelAction ?? .popViewController)

                }.foregroundColor(Color.white)
            }
        }
            
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(GDLocalizedString("general.alert.done")) {
                do {
                    try save()
                } catch {
                    alert = .saveError
                    showAlert = true
                }
            }
            .foregroundColor(Color.white)
            .accessibility(hint: GDLocalizedTextView("markers.edit_screen.done_button.acc_hint"))
        }
    }
    
    var body: some View {
        ZStack {
            Color.quaternaryBackground.ignoresSafeArea()
            
            if isFetchingNameAndAddress {
                VStack(alignment: .center) {
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        ProgressView(GDLocalizedString("general.loading.loading"))
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryForeground))
                            .foregroundColor(.primaryForeground)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                VStack {
                    ScrollView {
                        if let route = config.route {
                            HStack {
                                GDLocalizedTextView("markers.edit_screen.route", route)
                                    .padding([.leading, .trailing])
                                    .padding([.top, .bottom], 8)
                                Spacer()
                            }
                            .font(.callout)
                            .background(Color.secondaryBackground)
                        }
                        
                        VStack(alignment: .leading) {
                            GDLocalizedTextView("markers.sort_button.sort_by_name")
                                .foregroundColor(Color.tertiaryForeground)
                                .font(.callout)
                                .accessibilityHidden(true)
                            
                            TextField(GDLocalizedString("markers.sort_button.sort_by_name"), text: $displayName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .foregroundColor(.quaternaryBackground)
                                .accessibility(label: GDLocalizedTextView("markers.sort_button.sort_by_name"))
                                .padding([.bottom])
                            
                            GDLocalizedTextView("markers.annotation")
                                .foregroundColor(Color.tertiaryForeground)
                                .font(.callout)
                                .accessibilityHidden(true)
                            
                            TextEditor(text: $displayAnnotation)
                                .cornerRadius(5.0)
                                .layoutPriority(1)
                                .frame(minHeight: 100)
                                .foregroundColor(.quaternaryBackground)
                                .accessibility(label: GDLocalizedTextView("markers.annotation"))
                        }
                        .padding()
                    }
                    .foregroundColor(.primaryForeground)
                    
                    ExpandableMapView(style: .location(detail: updatedLocation ?? locationDetail), isEditable: true, accessibilityEditableMapViewModel: accessibilityEditableMapViewModel, isMapsButtonHidden: true) { updated, isAccessibilityEditing in
                        updatedLocation = updated
                        
                        isFetchingNameAndAddress = true
                        LocationDetail.fetchNameAndAddressIfNeeded(for: updated) { (newValue) in
                            isFetchingNameAndAddress = false
                            updatedLocation = newValue
                            
                            if isAccessibilityEditing {
                                if isPlayingBeacon == false {
                                    beaconDemo.prepare()
                                    beaconDemo.play(shouldTimeOut: false, newBeaconLocation: newValue.location)
                                    
                                    isPlayingBeacon = true
                                    
                                    onAccessibilityEditLocation(newValue, oldValue: locationDetail, isFirst: true)
                                } else {
                                    onAccessibilityEditLocation(newValue, oldValue: locationDetail)
                                }
                            }
                        }
                    }
                    .accessibility(label: Text(displayAddress))
                    
                    if deleteIsEnabled {
                        Button {
                            alert = .delete
                            showAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                GDLocalizedTextView("markers.action.delete")
                                    .lineLimit(1)
                                    .font(.system(size: fontSize))
                                Spacer()
                            }
                            .roundedBackground(Color.errorBackground)
                        }
                        .foregroundColor(.primaryForeground)
                        .padding()
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(title)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarItems }
        .alert(isPresented: $showAlert, content: { alertView })
        .onAppear {
            GDATelemetry.trackScreenView("marker_edit")
            
            isFetchingNameAndAddress = true
            LocationDetail.fetchNameAndAddressIfNeeded(for: locationDetail) { (newValue) in
                isFetchingNameAndAddress = false
                locationDetail = newValue
                displayName = newValue.displayName
                displayAddress = newValue.displayAddress
            }
        }
        .onDisappear {
            beaconDemo.restoreState()
            isPlayingBeacon = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            beaconDemo.restoreState()
            isPlayingBeacon = false
        }
    }
    
    private func onAccessibilityEditLocation(_ newValue: LocationDetail, oldValue: LocationDetail, isFirst: Bool = false) {
        guard let distance = newValue.labels.distance(from: oldValue.location) else {
            return
        }
        
        let distanceText = distance.accessibilityText ?? distance.text
        
        let firstAnnoucement = GDLocalizedString("location_detail.map.edit.accessibility.beacon.callout", distanceText)
        let defaultAnnoucement = GDLocalizedString("location_detail.map.edit.accessibility_annoucement", distanceText)
        
        let annoucement = isFirst ? firstAnnoucement : defaultAnnoucement
        
        // Post accessibility annoucement
        UIAccessibility.post(notification: .announcement, argument: annoucement)
        
        beaconDemo.updateBeaconLocation(newValue.location)
    }
    
    private func save() throws {
        let markerId: String
        
        // Clean up the text fields
        let nickname = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let annotation = displayAnnotation.trimmingCharacters(in: .whitespaces)
        
        // `nickname` should be different than `name`. Save empty strings as `nil`
        let finalNickname: String?
        if updatedLocation != nil {
            finalNickname = nickname.isEmpty ? updatedLocation?.nickname : nickname
        } else {
            finalNickname = nickname.isEmpty || nickname == locationDetail.source.name ? nil : nickname
        }
        
        let finalAnnotation = annotation.isEmpty ? nil : annotation
        let detail = updatedLocation ?? locationDetail
        
        if let id = locationDetail.markerId ?? SpatialDataCache.referenceEntity(source: locationDetail.source, isTemp: true)?.id {
            // Save marker ID
            markerId = id
            
            // If this is an existing marker (or in the same location as an existing marker), then update it
            try updateExisting(id: id,
                               coordinate: detail.location.coordinate,
                               nickname: finalNickname,
                               address: detail.estimatedAddress,
                               annotation: finalAnnotation)
        } else if case .entity(let id) = locationDetail.source, updatedLocation == nil {
            // If this is a new marker that refers to an underlying POI, create a new reference point
            markerId = try ReferenceEntity.add(entityKey: id,
                                               nickname: finalNickname,
                                               estimatedAddress: detail.estimatedAddress,
                                               annotation: finalAnnotation,
                                               context: config.context)
        } else {
            // If this is a new marker in some generic location (not referencing an underlying POI), create
            // a reference point to the generic location
            let loc = GenericLocation(lat: detail.location.coordinate.latitude,
                                      lon: detail.location.coordinate.longitude)
            markerId = try ReferenceEntity.add(location: loc,
                                               nickname: finalNickname,
                                               estimatedAddress: detail.estimatedAddress,
                                               annotation: finalAnnotation,
                                               temporary: false,
                                               context: config.context)
        }
        
        if let marker = LocationDetail(markerId: markerId) {
            config.onLocationDidUpdate?(marker)
        }
        
        navHelper.onNavigationAction(config.addOrUpdateAction)
    }
    
    private func updateExisting(id: String, coordinate: CLLocationCoordinate2D?, nickname: String?, address: String?, annotation: String?) throws {
        try autoreleasepool {
            guard let entity = SpatialDataCache.referenceEntityByKey(id) else {
                return
            }
            
            try ReferenceEntity.update(entity: entity, location: coordinate, nickname: nickname, address: address, annotation: annotation, context: config.context, isTemp: false)
            
            GDATelemetry.track("markers.edited", with: [
                "includesAnnotation": String(!(annotation?.isEmpty ?? true)),
                "updatedLocation": String(coordinate != nil),
                "context": config.context ?? "none"
            ])
        }
    }
    
    private func delete() {
        guard let id = locationDetail.markerId else {
            return
        }
        
        do {
            try ReferenceEntity.remove(id: id)
        } catch {
            GDLogAppError("Unable to successfully delete the reference entity (id: \(id))")
        }
        
        // TODO: Notify the rest of the app that the deletion has been completed
        
        navHelper.onNavigationAction(config.deleteAction ?? .popViewController)
    }
}

struct EditMarkerView_Previews: PreviewProvider {
    static var config: EditMarkerConfig {
        let imported = ImportedLocationDetail(nickname: "Serious Pie",
                                            annotation: "You will smell pizza baking as you walk past this restaurant")
        
        let detail = LocationDetail(location: CLLocation.sample,
                                    imported: imported,
                                    telemetryContext: "route_detail")
        
        return EditMarkerConfig(detail: detail, route: "Test Route")
    }
    
    static var previews: some View {
        NavigationView {
            EditMarkerView(config: config).navigationBarTitleDisplayMode(.inline)
        }
    }
}
