//
//  RoutesList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import RealmSwift

struct RoutesList: View {
    @EnvironmentObject var navHelper: MarkersAndRoutesListNavigationHelper
    @ObservedObject private var loader = RouteLoader()
    
    @Binding private var sort: SortStyle
    
    @State private var showAlert: Bool = false
    @State private var alert: Alert?
    @State private var selectedDetail: RouteDetail?
    @State private var showEditView = false
    @State private var goToNavDestination: Bool = false {
        didSet {
            if goToNavDestination == false {
                selectedDetail = nil
            }
        }
    }
    @State private var isPresentingFirstUseShareAlert = false
    @State private var isPresentingForRouteId: String?
    
    let activeRouteID: String?
    
    init(sort style: Binding<SortStyle>) {
        _sort = style
        
        if let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance,
           case let .database(id) = routeGuidance.content.source {
            activeRouteID = id
        } else {
            activeRouteID = nil
        }
        
        loader.load(sort: sort)
    }
    
    private func presentShareActivityViewController() {
        guard let id = isPresentingForRouteId else {
            return
        }
        
        let detail = RouteDetail(source: .database(id: id))
        let context = ShareRouteActivityViewRepresentable(route: detail)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .presentAnyModalViewController, object: self, userInfo: [AnyModalViewObserver.Keys.context: context])
        }
    }
    
    @ViewBuilder var selectedDetailView: some View {
        if let detail = selectedDetail {
            if showEditView {
                RouteEditView(style: .edit(detail: detail), deleteAction: .popViewController)
                    .environmentObject(navHelper as ViewNavigationHelper)
            } else {
                RouteDetailsView(detail, deleteAction: .popToViewController(type: MarkersAndRoutesListHostViewController.self))
                    .environmentObject(UserLocationStore())
                    .environmentObject(navHelper as ViewNavigationHelper)
            }
        }
    }
    
    var body: some View {
        if !loader.loadingComplete {
            LoadingMarkersOrRoutesView()
        } else if loader.routeIDs.isEmpty {
            EmptyMarkerOrRoutesView(.routes)
                .background(Color.quaternaryBackground)
                .onAppear {
                    GDATelemetry.trackScreenView("routes_list.empty")
                }
        } else {
            VStack(spacing: 0) {
                SortStyleCell(listName: GDLocalizedString("routes.title"), sort: _sort)
                
                ForEach(loader.routeIDs, id: \.self) { id in
                    RouteCell(model: RouteModel(id: id))
                        .accessibilityAddTraits(.isButton)
                        .conditionalAccessibilityAction(AppContext.shared.eventProcessor.activeBehavior is SoundscapeBehavior && activeRouteID == nil, named: Text(RouteActionState(.startRoute).text)) {
                            GDATelemetry.track("routes.start", with: ["source": "accessibility_action"])
                            
                            let routeGuidance = RouteGuidance(.init(source: .database(id: id)),
                                                              spatialData: AppContext.shared.spatialDataContext,
                                                              motion: AppContext.shared.motionActivityContext)
                            AppContext.shared.eventProcessor.activateCustom(behavior: routeGuidance)
                            navHelper.popToRootViewController(animated: true)
                        }
                        .conditionalAccessibilityAction(id == activeRouteID, named: Text(RouteActionState(.stopRoute).text)) {
                            GDATelemetry.track("routes.stop", with: ["source": "accessibility_action"])
                            
                            AppContext.shared.eventProcessor.deactivateCustom()
                        }
                        .conditionalAccessibilityAction(id != activeRouteID, named: Text(RouteActionState(.edit).text)) {
                            GDATelemetry.track("routes.edit", with: ["source": "accessibility_action"])
                            
                            selectedDetail = RouteDetail(source: .database(id: id))
                            showEditView = true
                            goToNavDestination = true
                        }
                        .conditionalAccessibilityAction(id != activeRouteID, named: GDLocalizedTextView("general.alert.delete")) {
                            GDATelemetry.track("routes.delete", with: ["source": "accessibility_action"])
                            
                            alert = confirmationAlert(for: id)
                            showAlert = true
                        }
                        .accessibilityAction(named: Text(RouteActionState(.share).text), {
                            GDATelemetry.track("routes.share", with: ["source": "accessibility_action"])
                            
                            isPresentingForRouteId = id
                            
                            if FirstUseExperience.didComplete(.share) {
                                presentShareActivityViewController()
                            } else {
                                isPresentingFirstUseShareAlert = true
                            }
                        })
                        .onDelete {
                            delete(id)
                        }
                        .onTapGesture {
                            selectedDetail = RouteDetail(source: .database(id: id))
                            showEditView = false
                            goToNavDestination = true
                        }
                }
            }
            .background(Color.quaternaryBackground)
            .alert(isPresented: $showAlert, content: { alert ?? errorAlert() })
            
            NavigationLink(destination: selectedDetailView, isActive: $goToNavDestination) {
                EmptyView()
            }
            .accessibilityHidden(true)
            .onAppear {
                GDATelemetry.trackScreenView("routes_list")
            }
            .alert(isPresented: $isPresentingFirstUseShareAlert, content: {
                return SoundscapeDocumentAlert.firstUseExperience {
                    FirstUseExperience.setDidComplete(for: .share)
                    
                    presentShareActivityViewController()
                }
            })
        }
    }
    
    private func confirmationAlert(for id: String) -> Alert {
        let confirm: Alert.Button = .destructive(GDLocalizedTextView("general.alert.delete")) {
            delete(id)
        }
        
        let cancel: Alert.Button = .cancel(GDLocalizedTextView("general.alert.cancel")) {
            selectedDetail = nil
        }
        
        return Alert(title: GDLocalizedTextView("route_detail.edit.delete.title"),
                     message: GDLocalizedTextView("general.alert.destructive_undone_message"),
                     primaryButton: confirm,
                     secondaryButton: cancel)
    }
    
    private func errorAlert() -> Alert {
         Alert(title: GDLocalizedTextView("general.error.error_occurred"),
               message: GDLocalizedTextView("routes.action.deleted_error"),
               dismissButton: nil)
    }
    
    private func delete(_ id: String) {
        do {
            try loader.remove(id: id)
        } catch {
            alert = errorAlert()
            showAlert = true
        }
    }
}

struct RoutesList_Previews: PreviewProvider {
    static var previews: some View {
        RoutesList(sort: .constant(.alphanumeric))
            .environmentObject(MarkersAndRoutesListNavigationHelper())
    }
}
