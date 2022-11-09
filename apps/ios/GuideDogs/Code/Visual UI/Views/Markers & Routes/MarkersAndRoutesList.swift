//
//  MarkersAndRoutesList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import SwiftUI
import CoreLocation
import RealmSwift

struct MarkerRouteTabButton: View {
    let name: String
    let icon: String
    let index: Int
    let count: Int
    private let value: MarkersAndRoutesList.List
    
    @CustomScaledMetric(maxValue: 26.0, relativeTo: .caption) var fontSize: CGFloat = Font.TextStyle.caption.pointSize
    @CustomScaledMetric(maxValue: 48.0, relativeTo: .title) var imageSize: CGFloat = Font.TextStyle.title.pointSize
    
    @Binding private var selected: MarkersAndRoutesList.List
    
    fileprivate init(name: String, icon: String, index: Int, of: Int, value: MarkersAndRoutesList.List, selected: Binding<MarkersAndRoutesList.List>) {
        self.name = name
        self.icon = icon
        self.index = index
        self.count = of
        self.value = value
        self._selected = selected
    }
    
    var button: some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 4.0) {
                Image(icon)
                    .font(.system(size: imageSize))
                
                Text(name)
                    .font(.system(size: fontSize))
            }
            Spacer()
        }
        .padding()
        .background(Color.secondaryBackground)
    }
    
    var body: some View {
        if selected == value {
            button
                .foregroundColor(.primaryForeground)
                .accentColor(.primaryForeground)
                .accessibilityElement(children: .ignore)
                .accessibility(addTraits: .isSelected)
                .accessibility(label: GDLocalizedTextView("general.tabs", name, String(index), String(count)))
        } else {
            button
                .foregroundColor(.quaternaryForeground)
                .accentColor(.quaternaryForeground)
                .accessibilityElement(children: .ignore)
                .accessibility(label: GDLocalizedTextView("general.tabs", name, String(index), String(count)))
                .onTapGesture {
                    selected = value
                }
        }
    }
}

struct MarkersAndRoutesList: View {
    @EnvironmentObject var navHelper: MarkersAndRoutesListNavigationHelper
    
    @State private var selectedList: List = .markers
    @State var sort: SortStyle
    
    fileprivate enum List: String, CaseIterable, Identifiable {
        case markers
        case routes
        
        var id: List { self }
    }
    
    init() {
        _sort = State(initialValue: SettingsContext.shared.defaultMarkerSortStyle)
        
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = Colors.Foreground.primary
        appearance.backgroundColor = Colors.Background.tertiary
        appearance.setTitleTextAttributes([.foregroundColor: Colors.Background.secondary!],
                                          for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: Colors.Foreground.primary!],
                                          for: .normal)
        
        let proxy = UINavigationBar.appearance()
        proxy.configureAppearance(for: .default)
        proxy.standardAppearance.shadowColor = .clear
        proxy.scrollEdgeAppearance?.shadowColor = .clear
        proxy.compactAppearance?.shadowColor = .clear
    }
    
    var body: some View {
        ZStack {
            // Background color that extends past the safe area
            Color.quaternaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    if selectedList == .markers {
                        MarkersList(sort: $sort)
                    } else {
                        RoutesList(sort: $sort)
                    }
                }
                .padding([.top], 1)
                
                HStack {
                    MarkerRouteTabButton(name: GDLocalizedString("markers.title"),
                                         icon: "marker.fill",
                                         index: 1,
                                         of: 2,
                                         value: .markers,
                                         selected: $selectedList)
                    MarkerRouteTabButton(name: GDLocalizedString("routes.title"),
                                         icon: "route.fill",
                                         index: 2,
                                         of: 2,
                                         value: .routes,
                                         selected: $selectedList)
                }
                .background(Color.secondaryBackground
                                .ignoresSafeArea(.all, edges: [.bottom])
                                .shadow(color: .black, radius: 5.0, x: 0.0, y: -1.0))
                
            }
        }
        .navigationTitle(GDLocalizedTextView("search.view_markers"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if selectedList == .routes {
                    NavigationLink(destination: RouteEditView(style: .add, deleteAction: nil).environmentObject(navHelper as ViewNavigationHelper)) {
                        Image(systemName: "plus")
                            .font(.system(size: 22)) // Purposely fix the size since this is in a nav bar
                            .foregroundColor(.primaryForeground)
                            .padding([.all], 4)
                            .accessibilityLabel(GDLocalizedTextView("route_detail.action.create"))
                            .accessibilityHint(GDLocalizedTextView("route_detail.action.create.hint"))
                    }
                    .accessibilityElement(children: .combine)
                    .embedToolbarContent()
                }
            }
        }
    }
}

struct MarkersAndRoutesList_Previews: PreviewProvider {
    static var previews: some View {
        Realm.bootstrap()
        AppContext.shared.geolocationManager.mockLocation(CLLocation.sample)
        
        return NavigationView {
            MarkersAndRoutesList().navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.realmConfiguration, RealmHelper.databaseConfig)
        .environmentObject(UserLocationStore(designValue: CLLocation.sample))
        .environmentObject(MarkersAndRoutesListNavigationHelper())
    }
}
