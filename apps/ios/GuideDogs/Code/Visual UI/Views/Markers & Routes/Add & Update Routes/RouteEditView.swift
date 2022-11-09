//
//  RouteEditView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation
import RealmSwift

struct RouteEditView: View {
    private enum EditViewAlert {
        case delete, error, cancel
    }
    
    enum Style {
        case add
        case edit(detail: RouteDetail)
        case `import`(route: Route)
        
        var detail: RouteDetail? {
            switch self {
            case .add: return nil
            case .edit(let detail): return detail
            case .import(let route): return RouteDetail(source: .cache(route: route))
            }
        }
        
        var title: String {
            switch self {
            case .add: return GDLocalizedString("route_detail.action.create")
            case .edit: return GDLocalizedString("route_detail.action.edit")
            case .import(let route):
                if SpatialDataCache.routeByKey(route.id) == nil {
                    // Import a new route
                    return GDLocalizedString("route_detail.action.create")
                } else {
                    // Import an existing route
                    return GDLocalizedString("route_detail.action.edit")
                }
            }
        }
    }
    
    // MARK: Properties
    
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    @CustomScaledMetric(maxValue: 26.0, relativeTo: .body) var fontSize: CGFloat = Font.TextStyle.body.pointSize
    
    @State private var name = ""
    @State private var description = ""
    @State private var identifiableWaypoints: [IdentifiableLocationDetail] = []
    
    // Alerts
    @State private var alert: EditViewAlert?
    @State private var showAlert: Bool = false
    
    let style: Style
    let deleteAction: NavigationAction?
    
    private var isValid: Bool {
        return name.isEmpty == false
    }
    
    private var routeContainsChanges: Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch style {
        case .add:
            return !(name.isEmpty && description.isEmpty && identifiableWaypoints.isEmpty)
        case .edit(let detail):
            return !(name == detail.name && description == detail.description && identifiableWaypoints.compactMap({ return $0.locationDetail.source }) == detail.waypoints.compactMap({ return $0.source }))
        case .import:
            return true
        }
    }
    
    // MARK: Initialization
    
    init(style: Style, deleteAction: NavigationAction?) {
        self.style = style
        self.deleteAction = deleteAction
        
        if let detail = style.detail {
            _identifiableWaypoints = State(initialValue: detail.waypoints.asIdenfifiable)
            
            if let name = detail.name {
                _name = State(initialValue: name)
            }
            
            if let description = detail.description {
                _description = State(initialValue: description)
            }
        }
        
        // Fill empty space in the list view
        UITableView.appearance().backgroundColor = Colors.Background.tertiary!
        
        // Disable vertical bounce when scrolling is not needed
        UIScrollView.appearance().alwaysBounceVertical = false
    }
    
    // MARK: Actions
    
    private func onCancel() {
        navHelper.popViewController(animated: true)
    }
    
    private func onDelete() {
        guard case .edit(let detail) = style else {
            return
        }
        
        guard case .database(let id) = detail.source else {
            return
        }
        
        do {
            try Route.delete(id)
            
            navHelper.onNavigationAction(deleteAction ?? .popViewController)
        } catch {
            alert = .error
            showAlert = true
        }
    }
    
    private func onDone() {
        // Remove leading and trailing whitespaces and new lines
        _name.wrappedValue = name.trimmingCharacters(in: .whitespacesAndNewlines)
        _description.wrappedValue = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            switch style {
            case .add: try onAddRoute()
            case .edit(let detail): try onUpdateRoute(detail)
            case .import(let route): try onImportRoute(route)
            }
            
            navHelper.popViewController(animated: true)
        } catch {
            alert = .error
            showAlert = true
        }
    }
    
    private func onAddRoute() throws {
        let route = Route(name: name, description: description, waypoints: identifiableWaypoints.asRouteWaypoint)
        
        try Route.add(route)
    }
    
    private func onUpdateRoute(_ detail: RouteDetail) throws {
        guard case .database(let id) = detail.source else {
            // Route does not exist in database
            throw RouteRealmError.doesNotExist
        }
        
        try Route.update(id: id, name: name, description: description, waypoints: identifiableWaypoints.asLocationDetail)
    }
    
    private func onImportRoute(_ route: Route) throws {
        if name != route.name {
            // If the name has changed from what was imported,
            // update it
            route.name = name
        }
        
        if route.routeDescription != description {
            // Update description
            route.routeDescription = description
        }
        
        if route.waypoints.ordered.asLocationDetail.compactMap({ return $0.source }) != identifiableWaypoints.compactMap({ return $0.locationDetail.source }) {
            // Update waypoints
            route.waypoints.removeAll()
            route.waypoints.append(objectsIn: identifiableWaypoints.asRouteWaypoint)
        }
        
        try Route.add(route)
    }
    
    private var alertView: Alert {
        switch alert {
        case .delete:
            return Alert(title: GDLocalizedTextView("route_detail.edit.delete.title"),
                         message: GDLocalizedTextView("route_detail.edit.delete.message"),
                         primaryButton: .cancel(GDLocalizedTextView("general.alert.cancel")),
                         secondaryButton: .destructive(GDLocalizedTextView("general.alert.delete"), action: { onDelete() }))
            
        case .cancel:
            return Alert(title: GDLocalizedTextView("route_detail.edit.cancel.title"),
                         message: GDLocalizedTextView("route_detail.edit.cancel.message"),
                         primaryButton: .cancel(GDLocalizedTextView("general.alert.cancel")),
                         secondaryButton: .destructive(GDLocalizedTextView("general.alert.discard"), action: { onCancel() }))
        default:
            return Alert(title: GDLocalizedTextView("universal_links.alert.error.title"),
                         message: GDLocalizedTextView("general.alert.error.message"),
                         dismissButton: .default(GDLocalizedTextView("general.alert.dismiss")))
        }
    }
    
    @ViewBuilder
    private var header: some View {
        WaypointAddButton(name: $name, identifiableWaypoints: $identifiableWaypoints)
            .listRowInsets(.none)
    }
    
    // MARK: `body`
    
    var body: some View {
        ZStack {
            // Background color that extends past the safe area
            Color.tertiaryBackground
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0.0) {
                List {
                    VStack(alignment: .center, spacing: 24.0) {
                        // Name Field
                        TitledTextField(field: .name, value: $name)
                            .autocapitalization(.words)
                        
                        // Description Field
                        TitledTextField(field: .description, value: $description)
                            .autocapitalization(.sentences)
                    }
                    .padding(24.0)
                    .plainListRowBackground(Color.tertiaryBackground)
                    
                    Section(header: header) {
                        if identifiableWaypoints.count > 0 {
                            WaypointEditList(identifiableWaypoints: $identifiableWaypoints)
                        } else {
                            RouteEditTutorialView()
                                .plainListRowBackground(Color.tertiaryBackground)
                                .padding(.horizontal, 24.0)
                                .padding(.vertical, 12.0)
                        }
                    }
                    // Do not capitalize text in the section heading
                    .textCase(nil)
                    // Do not use default font in the section heading
                    .font(nil)
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, .constant(.active))
                .colorScheme(.dark)
                
                // Hide the delete button when creating a new route or saving an
                // imported route (e.g., `parameters != nil`)
                if case .edit = style {
                    Spacer()
                    
                    Button(GDLocalizedString("route_detail.edit.delete")) {
                        // Ensure the keyboard is hidden when the delete button is pressed
                        hideKeyboard()
                        
                        alert = .delete
                        showAlert = true
                    }
                    .font(.system(size: fontSize))
                    .foregroundColor(Color.primaryForeground)
                    .roundedBackground(Color.red)
                    .padding(.horizontal, 48.0)
                    .padding(.vertical, 24.0)
                }
            }
            
        }
        .navigationBarTitle(style.title, displayMode: .inline)
        // Hide `Back` button and present `Cancel` button
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(GDLocalizedString("general.alert.cancel")) {
                    if routeContainsChanges {
                        alert = .cancel
                        showAlert = true
                    } else {
                        onCancel()
                    }
                }
                .foregroundColor(Color.primaryForeground)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(GDLocalizedString("general.alert.done")) {
                    onDone()
                }
                .foregroundColor(Color.primaryForeground)
                .if(!isValid, transform: { $0.hidden() })
            }
        })
        .alert(isPresented: $showAlert, content: { alertView })
        .onAppear {
            GDATelemetry.trackScreenView("route_edit")
        }
    }
}

struct RouteEditView_Previews: PreviewProvider {
    
    static var uStore: UserLocationStore {
        let location = CLLocation(latitude: 47.640179, longitude: -122.111320)
        return UserLocationStore(designValue: location)
    }
    
    static var previews: some View {
        Group {
            NavigationView {
                RouteEditView(style: .add, deleteAction: nil)
            }
            
            NavigationView {
                RouteEditView(style: .edit(detail: RouteDetailsView_Previews.testOMRoute), deleteAction: nil)
            }
            
        }
        .environmentObject(MarkersAndRoutesListNavigationHelper())
        .environmentObject(uStore)
    }
    
}
