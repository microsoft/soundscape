//
//  WaypointCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

enum WaypointCellGuidanceState {
    case none
    case previous
    case current
    case next
    case future
    
    var strokeColors: (Color, Color, Color) {
        switch self {
        case .next: return (Color.white, Color.yellow, Color.white)
        default: return (Color.white, Color.white, Color.white)
        }
    }
    
    var strokeWidths: (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .previous: return (2.0, 2.0, 2.0)
        case .current: return (2.0, 2.0, 1.0)
        case .next: return (1.0, 2.0, 1.0)
        default: return (1.0, 1.0, 1.0)
        }
    }
    
    var strokeStyles: (StrokeStyle, StrokeStyle, StrokeStyle) {
        let normal = StrokeStyle(lineWidth: 1.0)
        let bold = StrokeStyle(lineWidth: 2.0)
        let dashed = StrokeStyle(lineWidth: 1.0, lineCap: CGLineCap.round, dash: [5.0])
        
        switch self {
        case .none: return (normal, normal, normal)
        case .previous: return (bold, bold, bold)
        case .current: return (bold, bold, dashed)
        case .next: return (dashed, bold, dashed)
        case .future: return (dashed, dashed, dashed)
        }
    }
}

enum WaypointCellDisplayStyle {
    case only
    case first
    case mid
    case last
}

struct WaypointCell: View {
    @CustomScaledMetric(relativeTo: .headline) private var cellTextPadding: CGFloat = 16.0
    @CustomScaledMetric(maxValue: 16.0, relativeTo: .caption) private var indexTextPadding: CGFloat = 8.0
    
    @EnvironmentObject var user: UserLocationStore
    
    enum IndexWidth: Preference {}
    
    let index: Int
    let count: Int
    let detail: LocationDetail
    let showAddress: Bool
    let currentWaypointIndex: Int?
    let textWidth: CGFloat?
    
    init(index: Int, count: Int, detail: LocationDetail, showAddress: Bool, currentWaypointIndex: Int?, textWidth: CGFloat? = nil) {
        self.index = index
        self.count = count
        self.detail = detail
        self.showAddress = showAddress
        self.currentWaypointIndex = currentWaypointIndex
        self.textWidth = textWidth
    }
    
    private var state: WaypointCellGuidanceState {
        guard let currentIndex = currentWaypointIndex else {
            return .none
        }
        
        if index < currentIndex - 1 {
            return .previous
        } else if index == currentIndex - 1 {
            return .current
        } else if index == currentIndex {
            return .next
        } else {
            return .future
        }
    }
    
    private var style: WaypointCellDisplayStyle {
        guard count > 1 else {
            return .only
        }
        
        if index == 0 {
            return .first
        } else if index == count - 1 {
            return .last
        } else {
            return .mid
        }
    }
    
    private var indexAccessibilityLabel: String {
        guard let current = currentWaypointIndex, index <= current else {
            return GDLocalizedString("location_detail.waypoint", String(index + 1))
        }
        
        if index == current {
            return GDLocalizedString("route_detail.waypoint.current_beacon", String(index + 1))
        } else {
            return GDLocalizedString("location_detail.waypoint", String(index + 1))
        }
    }
    
    private var locationDetailLabel: LocalizedLabel? {
        return detail.labels.distance(from: user.location)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 0) {
                Text(String(index + 1))
                    .font(Font.caption.monospacedDigit())
                    .fixedSize(horizontal: true, vertical: true)
                    .foregroundColor(Color.primaryForeground)
                    .readGeometryPreference(key: MaxValue<IndexWidth, CGFloat>.self) { $0.size.width }
            }
            .frame(width: textWidth)
            .padding(indexTextPadding)
            .frame(maxHeight: .infinity, alignment: .center)
            .background(WaypointIndexBackground(state: state))
            .padding(24.0)
            .background(WaypointPathBackground(state: state, style: style))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(indexAccessibilityLabel))
            .accessibilitySortPriority(5)
            
            VStack(alignment: .leading) {
                Text(detail.displayName)
                    .font(.headline)
                    .foregroundColor(Color.primaryForeground)
                    .accessibilitySortPriority(4)
                
                Text(locationDetailLabel?.text ?? "")
                    .font(.subheadline)
                    .foregroundColor(Color.yellowHighlight)
                    .accessibilityLabel(Text(locationDetailLabel?.accessibilityText ?? ""))
                    .accessibilitySortPriority(3)
                
                if showAddress {
                    Text(detail.displayAddress)
                        .font(.subheadline)
                        .foregroundColor(Color.tertiaryForeground)
                        .accessibilitySortPriority(2)
                }
            }
            .padding([.top, .bottom, .trailing], cellTextPadding)
            .frame(maxHeight: .infinity, alignment: .center)
            
            Spacer()
        }
        .background(Color.primaryBackground)
        .fixedSize(horizontal: false, vertical: true)
        
    }
}

struct WaypointCell_Previews: PreviewProvider {
    static var detail: LocationDetail {
        let wpt = ActivityWaypoint(coordinate: .init(latitude: 47.621901, longitude: -122.341150),
                                   name: "Bike Rack on Westlake",
                                   description: "This bike rack is in the middle of the sidewalk. Use your cane to detect it")
        
        let detail = ImportedLocationDetail(nickname: wpt.name,
                                            annotation: wpt.description,
                                            departure: wpt.departureCallout,
                                            arrival: wpt.arrivalCallout)
        
        return LocationDetail(location: CLLocation(wpt.coordinate),
                              imported: detail,
                              telemetryContext: "route_detail")
    }
    
    static var detailWithAddress: LocationDetail {
        let location = CLLocation(latitude: 47.621901, longitude: -122.341150)
        
        let detail = ImportedLocationDetail(nickname: "Bike Rack on Westlake",
                                            annotation: "This bike rack is in the middle of the sidewalk. Use your cane to detect it",
                                            departure: nil,
                                            arrival: nil)
        let source: LocationDetail.Source = .designData(at: location,
                                                        address: "123 Fake Avenue on the Boulevard of Long Test Strings in the district of tests, Testing, Testington 98765")
        
        return LocationDetail(designTimeSource: source,
                              imported: detail,
                              telemetryContext: "test")!
    }
    
    static var location: UserLocationStore {
        return UserLocationStore(designValue: .init(latitude: 47.621701, longitude: -122.341150))
    }
    
    static var previews: some View {
        VStack(spacing: 0) {
            WaypointCell(index: 0,
                         count: 2,
                         detail: detailWithAddress,
                         showAddress: true,
                         currentWaypointIndex: nil)
                .environmentObject(location)
                .previewLayout(.sizeThatFits)
            
            WaypointCell(index: 1,
                         count: 2,
                         detail: detailWithAddress,
                         showAddress: true,
                         currentWaypointIndex: nil)
                .environmentObject(location)
                .previewLayout(.sizeThatFits)
        }
        .previewLayout(.sizeThatFits)
        
        VStack(spacing: 0) {
            WaypointCell(index: 0,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: nil)
                .environmentObject(location)
                .previewLayout(.sizeThatFits)
            
            WaypointCell(index: 1,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: nil)
                .environmentObject(location)
                .previewLayout(.sizeThatFits)
            
            WaypointCell(index: 2,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: nil)
                .environmentObject(location)
                .previewLayout(.sizeThatFits)
        }
        .previewLayout(.sizeThatFits)
        
        VStack(spacing: 0) {
            
            WaypointCell(index: 0,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: 0)
                .environmentObject(location)
            
            WaypointCell(index: 1,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: 0)
                .environmentObject(location)
            
            WaypointCell(index: 2,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: 0)
                .environmentObject(location)
        }
        .previewLayout(.sizeThatFits)
        
        VStack(spacing: 0) {
            WaypointCell(index: 0,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: 2)
                .environmentObject(location)
            
            WaypointCell(index: 1,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: 2)
                .environmentObject(location)
            
            WaypointCell(index: 2,
                         count: 3,
                         detail: detail,
                         showAddress: false,
                         currentWaypointIndex: 2)
                .environmentObject(location)
        }
        .previewLayout(.sizeThatFits)
        
        WaypointCell(index: 1,
                     count: 3,
                     detail: detail,
                     showAddress: false,
                     currentWaypointIndex: 2)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .environmentObject(location)
            .previewLayout(.sizeThatFits)
    }
}
