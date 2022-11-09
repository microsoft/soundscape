//
//  AuthoredActivitiesList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct ActivityCellButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
      configuration.label
          .scaleEffect(configuration.isPressed ? 0.96 : 1)
          .shadow(color: configuration.isPressed ? Color.white : Color.clear, radius: 3.0, x: 0, y: 0)
          .animation(.easeIn(duration: 0.1))
  }
}

struct EmptyActivitiesList: View {
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Text(GDLocalizedString("behavior.experiences.no_events.title"))
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .foregroundColor(Color.primaryForeground)
                Spacer()
            }
            
            Text(GDLocalizedString("behavior.experiences.no_events.caption.1") + "\n\n" + GDLocalizedString("behavior.experiences.no_events.caption.2"))
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(Color.primaryForeground)
                .padding()
        }
        .padding([.top, .bottom], 64.0)
    }
}

struct AuthoredActivitiesList: View {
    @EnvironmentObject var activityStorage: AuthoredActivityStorage
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    @State private var showingAlert = false
    @State private var selectedActivityId: String?
    @State private var editMode = false
    
    @ViewBuilder
    private func detailsView(for activity: AuthoredActivityContent) -> some View {
        switch activity.type {
        case .orienteering:
            RouteDetailsView(RouteDetail(source: .trailActivity(content: activity)), deleteAction: nil)
                .environmentObject(UserLocationStore())
                .environmentObject(navHelper)
            
        case .guidedTour:
            GuidedTourDetailsView(TourDetail(content: activity))
                .environmentObject(UserLocationStore())
                .environmentObject(navHelper)
        }
    }
    
    private func resetActivity(checkForUpdates: Bool = false) {
        guard let selected = selectedActivityId else {
            return
        }
        
        activityStorage.reset(selected)
        
        guard checkForUpdates else {
            UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("behavior.experiences.reset.confirmation"))
            return
        }
        
        activityStorage.update(selected)
    }
    
    var alert: Alert {
        Alert(title: Text(GDLocalizedString("behavior.experience.delete.title")),
              message: Text(GDLocalizedString("behavior.experience.delete.explanation")),
              primaryButton: .destructive(Text(GDLocalizedString("general.alert.delete"))) {
                activityStorage.remove(selectedActivityId)
                selectedActivityId = nil
              },
              secondaryButton: .cancel(Text(GDLocalizedString("general.alert.cancel"))) {
                selectedActivityId = nil
              })
    }
    
    var body: some View {
        ZStack {
            // Background color that extends past the safe area
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                if activityStorage.activities.count > 0 {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(activityStorage.activities, id: \.metadata.id) { activity in
                            HStack(alignment: .center) {
                                if editMode {
                                    Button {
                                        selectedActivityId = activity.metadata.id
                                        showingAlert = true
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundColor(Color.red)
                                            .background(Circle().fill(Color.white))
                                            .frame(width: 24, height: 24)
                                            .padding([.leading, .top, .bottom])
                                    }
                                    .transition(.slide)
                                }
                                
                                NavigationLink(destination: detailsView(for: activity.content)) {
                                    AuthoredActivityCell(activity: activity.content, isActive: activity.state == .active, isComplete: activity.state == .complete)
                                        .conditionalAccessibilityAction(activity.state != .active, named: Text(GDLocalizedString("behavior.experiences.delete_action"))) {
                                            selectedActivityId = activity.metadata.id
                                            showingAlert = true
                                        }
                                        .colorPalette(activity.content.type == .guidedTour ? Palette.Theme.teal : Palette.Theme.blue)
                                }
                                .padding([.leading, .top, .trailing], 12)
                                .buttonStyle(ActivityCellButtonStyle())
                            }
                        }
                        
                        Spacer()
                    }
                    .onAppear {
                        GDATelemetry.trackScreenView("asevents")
                    }
                } else {
                    EmptyActivitiesList()
                        .onAppear {
                            GDATelemetry.trackScreenView("asevents.empty")
                        }
                }
            }
        }
        .navigationTitle(GDLocalizedTextView("behavior.experiences.events_list_nav_title"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(editMode ? GDLocalizedString("general.alert.done") : GDLocalizedString("general.alert.edit")) {
                    withAnimation {
                        editMode.toggle()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Color.white)
            }
        }
        .alert(isPresented: $showingAlert) { alert }
    }
}

struct AdaptiveSportsEventsListView_Previews: PreviewProvider {
    static var emptyStorage: AuthoredActivityStorage {
        return AuthoredActivityStorage([])
    }
    
    static var storage: AuthoredActivityStorage {
        AuthoredActivityStorage([
            (AuthoredActivityContent(id: UUID().uuidString,
                                     type: .orienteering,
                                     name: GDLocalizationUnnecessary("Test Event"),
                                     creator: GDLocalizationUnnecessary("Our Team"),
                                     locale: Locale.enUS,
                                     availability: DateInterval(start: Date(), duration: 60 * 60 * 24 * 14),
                                     expires: true,
                                     image: nil,
                                     desc: GDLocalizationUnnecessary("This is a fun event! There will be a ton to do. You should come join us!"),
                                     waypoints: [],
                                     pois: []), .active),
            (AuthoredActivityContent(id: UUID().uuidString,
                                     type: .orienteering,
                                     name: GDLocalizationUnnecessary("Kayakathon"),
                                     creator: GDLocalizationUnnecessary("Outdoors for All"),
                                     locale: Locale.enUS,
                                     availability: DateInterval(start: Date(), duration: 60 * 60 * 4),
                                     expires: false,
                                     image: nil,
                                     desc: GDLocalizationUnnecessary("Paddle the lake with OFA!"),
                                     waypoints: [],
                                     pois: []), .complete),
            (AuthoredActivityContent(id: UUID().uuidString,
                                     type: .guidedTour,
                                     name: GDLocalizationUnnecessary("Kayakathon"),
                                     creator: GDLocalizationUnnecessary("Outdoors for All"),
                                     locale: Locale.enUS,
                                     availability: DateInterval(start: Date(), duration: 60 * 60 * 4),
                                     expires: false,
                                     image: nil,
                                     desc: GDLocalizationUnnecessary("Paddle the lake with OFA!"),
                                     waypoints: [],
                                     pois: []), .notComplete)
        ])
    }
    
    static var previews: some View {
        NavigationView {
            AuthoredActivitiesList()
                .navigationTitle(Text("Events"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(ViewNavigationHelper())
                .environmentObject(emptyStorage)
        }
        
        NavigationView {
            AuthoredActivitiesList()
                .navigationTitle(Text("Events"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(ViewNavigationHelper())
                .environmentObject(storage)
        }
        
        NavigationView {
            AuthoredActivitiesList()
                .navigationTitle(Text("Events"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(ViewNavigationHelper())
                .environmentObject(storage)
        }
        .environment(\.sizeCategory, .accessibilityMedium)
        
        NavigationView {
            AuthoredActivitiesList()
                .navigationTitle(Text("Events"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(ViewNavigationHelper())
                .environmentObject(storage)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
}
