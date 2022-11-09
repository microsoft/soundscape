//
//  AuthoredActivityCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import SDWebImageSwiftUI

struct ActivityMetadataFooter: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.colorPalette) var colorPalette
    
    let activityType: AuthoredActivityType
    let availability: DateInterval
    
    var shouldDisplayDate: Bool {
        return availability.start != .distantPast || availability.end != .distantFuture
    }
    
    var dateString: String {
        if availability.duration > 60 * 60 * 24 {
            // The activity runs for more than one day
            let formatter = DateIntervalFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            return formatter.string(from: availability.start, to: availability.end)
        } else {
            // The activity is on a specific day
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            return formatter.string(from: availability.start)
        }
    }
    
    @ViewBuilder
    private var layout: some View {
        if sizeCategory.isAccessibilityCategory {
            VStack(alignment: .leading) {
                HStack {
                    GDLocalizedTextView(activityType == .guidedTour ? "tour_detail.beacon.title" : "route_detail.orienteering.title")
                        .font(.subheadline.smallCaps())
                        .foregroundColor(colorPalette.neutralContrast)
                    
                    Spacer()
                }
                
                if shouldDisplayDate {
                    Text(dateString)
                        .font(.caption)
                }
            }
        } else {
            HStack(alignment: .lastTextBaseline) {
                GDLocalizedTextView(activityType == .guidedTour ? "tour_detail.beacon.title" : "route_detail.orienteering.title")
                    .font(.subheadline.smallCaps())
                    .foregroundColor(colorPalette.neutralContrast)
                
                Spacer()
                
                if shouldDisplayDate {
                    Text(dateString)
                        .font(.caption)
                }
            }
        }
    }
    
    var body: some View {
        layout.padding([.leading, .trailing])
            .padding([.top, .bottom], 8)
            .background(colorPalette.dark)
            .foregroundColor(colorPalette.neutralContrast)
    }
}

struct AuthoredActivityCell: View {
    @Environment(\.colorPalette) var colorPalette
    @ScaledMetric(relativeTo: .body) private var moreBtnSize: CGFloat = 28.0
        
    let activity: AuthoredActivityContent
    
    @State var isActive: Bool
    @State var isComplete: Bool
    
    init(activity: AuthoredActivityContent, isActive: Bool, isComplete: Bool) {
        self.activity = activity
        self._isActive = State(initialValue: isActive)
        self._isComplete = State(initialValue: isComplete)
    }
    
    @ViewBuilder private var stateBadge: some View {
        if isActive {
            ActiveBadge(colorPalette.light)
                .padding([.leading, .trailing], 8)
                .padding([.top, .bottom], 4)
                .background(colorPalette.dark)
                .accessibilitySortPriority(0)
        } else if isComplete {
            CompletionBadge(true, foreground: colorPalette.light, background: colorPalette.dark)
                .padding([.leading, .trailing], 8)
                .padding([.top, .bottom], 4)
                .background(colorPalette.dark)
                .accessibilitySortPriority(0)
        } else {
            EmptyView()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(colorPalette.neutralContrast)
                
                    Text(GDLocalizedString("behavior.scavenger_hunt.by_line", activity.creator))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorPalette.light)
                }
                
                Spacer()
            }
            .padding()
            .accessibilitySortPriority(2)
            
            ZStack(alignment: .topLeading) {
                if let imageURL = activity.image {
                    image(for: imageURL)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 240)
                        .clipped()
                        .accessibilityHidden(true)
                }
                
                stateBadge
                    .roundedBorder(lineColor: colorPalette.light, lineWidth: 1.0, cornerRadius: 5)
                    .padding()
                    .accessibilitySortPriority(3)
            }
            .padding(4.0)
            
            ActivityMetadataFooter(activityType: activity.type, availability: activity.availability)
                .accessibilitySortPriority(1)
        }
        .background(colorPalette.dark)
        .accessibilityElement(children: .combine)
        .roundedBorder(lineColor: colorPalette.light, lineWidth: 1.0, cornerRadius: 10.0)
        .onReceive(NotificationCenter.default.publisher(for: .activityStateReset)) { notification in
            guard let userInfo = notification.userInfo as? [String: Any] else {
                return
            }
            
            guard let id = userInfo[AuthoredActivityLoader.Keys.activityId] as? String else {
                return
            }
            
            guard id == activity.id else {
                return
            }
            
            self.isActive = false
            self.isComplete = false
        }
    }
    
    @ViewBuilder
    private func image(for url: URL) -> some View {
        // !! `WebImage` does not appear to use the cached image, if one exists
        // Manually check for and present the cached image
        if let cacheKey = SDWebImageManager.shared.cacheKey(for: url), let image = SDImageCache.shared.imageFromCache(forKey: cacheKey) {
            // Present cached image
            Image(uiImage: image)
                .resizable()
        } else {
            // Image has not been cached
            WebImage(url: url, context: nil)
                .resizable()
                .placeholder(Image("highlight-placeholder"))
        }
    }
}

struct AuthoredActivityCell_Previews: PreviewProvider {
    static var testData: AuthoredActivityContent {
        let availability = DateInterval(start: Date(), duration: 60 * 60 * 24 * 7)
        return AuthoredActivityContent(id: UUID().uuidString,
                                       type: .orienteering,
                                       name: GDLocalizationUnnecessary("Test Event"),
                                       creator: GDLocalizationUnnecessary("Our Team"),
                                       locale: Locale.enUS,
                                       availability: availability,
                                       expires: false,
                                       image: nil,
                                       desc: GDLocalizationUnnecessary("This is a fun event! There will be a ton to do. You should come join us!"),
                                       waypoints: [],
                                       pois: [])
    }
    
    static var testDataAlwaysAvailable: AuthoredActivityContent {
        let availability = DateInterval(start: .distantPast, end: .distantFuture)
        return AuthoredActivityContent(id: UUID().uuidString,
                                       type: .guidedTour,
                                       name: GDLocalizationUnnecessary("Test Event"),
                                       creator: GDLocalizationUnnecessary("Our Team"),
                                       locale: Locale.enUS,
                                       availability: availability,
                                       expires: false,
                                       image: nil,
                                       desc: GDLocalizationUnnecessary("This is a fun event! There will be a ton to do. You should come join us!"),
                                       waypoints: [],
                                       pois: [])
    }
    
    static var previews: some View {
        AuthoredActivityCell(activity: testDataAlwaysAvailable, isActive: true, isComplete: false)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: true, isComplete: false)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: true, isComplete: false)
            .environment(\.sizeCategory, .accessibilityMedium)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: true, isComplete: false)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: false, isComplete: true)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: false, isComplete: true)
            .environment(\.sizeCategory, .accessibilityMedium)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: false, isComplete: true)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: false, isComplete: false)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: false, isComplete: false)
            .environment(\.sizeCategory, .accessibilityMedium)
            .previewLayout(.sizeThatFits)
        
        AuthoredActivityCell(activity: testData, isActive: false, isComplete: false)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewLayout(.sizeThatFits)
    }
}
