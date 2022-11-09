//
//  RouteCompleteView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct RouteCompleteView: View {
    
    // MARK: Properties
    
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    @State var height: CGFloat = 0.0
    
    let route: RouteGuidance
    
    // MARK: Initialization
    
    init(route: RouteGuidance) {
        self.route = route
        
        // Disable vertical bounce when scrolling is not needed
        UIScrollView.appearance().bounces = false
    }
    
    // MARK: `body`
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0.0) {
                VStack(alignment: .leading, spacing: 4.0) {
                    let completed = "\(route.progress.completed)"
                    let total = "\(route.progress.total)"
                    let remaining = "\(route.progress.remaining)"
                    
                    let title = route.progress.isDone ? GDLocalizedString("route.end.completed", route.content.displayName) : GDLocalizedString("route.end.not_completed", route.content.displayName)
                    
                    let titleAccessibility = route.progress.isDone ? GDLocalizedString("route.end.completed.accessibility", route.content.displayName) : GDLocalizedString("route.end.not_completed.accessibility", route.content.displayName)
                    
                    let summary = route.progress.isDone ? GDLocalizedString("route.end.completed.summary", total) : GDLocalizedString("route.end.not_completed.summary", completed, total, remaining)
                    
                    let summaryAccessibility = route.progress.isDone ? GDLocalizedString("route.end.completed.summary.accessibility", total) : GDLocalizedString("route.end.not_completed.summary.accessibility", completed, total, remaining)
                    
                    // Title Text
                    
                    Text(title)
                        .titleTextFormat()
                        .accessibilityLabel(Text(titleAccessibility))
                    
                    Spacer()
                        .frame(height: 4.0)
                    
                    // Message Text - Summary and Time Elapsed
                       
                    Text(summary)
                        .messageTextFormat()
                        .accessibilityLabel(Text(summaryAccessibility))
                    
                    if let tLabel = route.content.labels.time {
                        let timeText = "\(tLabel.text)"
                        let timeAccessibilityText = "\(tLabel.accessibilityText ?? tLabel.text)"
                        
                        Group {
                            Text(Image(systemName: "timer"))
                                // Use a smaller font for images included in the message
                                // text
                                .font(.subheadline)
                                
                                + Text(" ")
                            
                                + Text(timeText)
                        }
                        .messageTextFormat()
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(timeAccessibilityText))
                    }
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                    .frame(height: 24.0)
                
                // Action Buttons
                
                VStack(alignment: .leading, spacing: 12.0) {
                    if route.progress.isDone == false {
                        Button(action: {
                            // Resume route
                            route.shouldResume = true
                            AppContext.shared.eventProcessor.activateCustom(behavior: route)
                            navHelper.dismiss(animated: true, completion: nil)
                        }, label: {
                            GDLocalizedTextView("general.alert.resume")
                                .actionButtonFormat()
                        })
                    }
                    
                    Button(action: {
                        // Dismiss via handler
                        navHelper.dismiss(animated: true, completion: nil)
                    }, label: {
                        GDLocalizedTextView("general.alert.dismiss")
                            .actionButtonFormat()
                    })
                }
                .padding(.horizontal, 18.0)
            }
            .padding(.horizontal, 18.0)
            .padding(.vertical, 24.0)
            .overlay(
                GeometryReader { reader in
                    Color.clear
                        .accessibilityHidden(true)
                        .onAppear {
                            height = min(reader.size.height, UIScreen.main.bounds.height / 2.0)
                        }
                }
            )
        }
        .frame(height: height)
        .linearGradientBackground(.darkBlue)
        .cornerRadius(5.0)
        .padding(12.0)
    }
}

struct RouteCompleteView_Previews: PreviewProvider {
    
    static let recreationalActivity = RouteDetailsView_Previews.testSportRoute
    static let route = RouteDetailsView_Previews.testOMRoute
    
    static var previews: some View {
        
        RouteCompleteView(route: RouteGuidance(recreationalActivity,
                                               spatialData: AppContext.shared.spatialDataContext,
                                               motion: AppContext.shared.motionActivityContext))
            .environmentObject(ViewNavigationHelper())
        
        RouteCompleteView(route: RouteGuidance(recreationalActivity,
                                               spatialData: AppContext.shared.spatialDataContext,
                                               motion: AppContext.shared.motionActivityContext))
            .environmentObject(ViewNavigationHelper())
        
    }
}

// MARK: Private Modifiers

private extension View {
    
    func titleTextFormat() -> some View {
        modifier(TitleTextFormat())
    }
    
    func messageTextFormat() -> some View {
        modifier(MessageTextFormat())
    }
    
    func actionButtonFormat() -> some View {
        modifier(ActionButtonFormat())
    }
    
}

private struct TitleTextFormat: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(.yellowHighlight)
            .font(.title)
            .accessibleTextFormat()
    }
    
}

private struct MessageTextFormat: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(.primaryForeground)
            .font(.body)
            .accessibleTextFormat()
    }
    
}

private struct ActionButtonFormat: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .roundedBackground(Color.primaryForeground)
            .accessibleTextFormat()
    }
    
}
