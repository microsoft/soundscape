//
//  WaypointImageCarousel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation
import SDWebImageSwiftUI

struct WaypointImageCarousel: View {
    
    // MARK: Properties
    
    let waypoint: WaypointDetail
    
    private var bottomPadding: Double {
        guard let images = waypoint.locationDetail?.images, !images.isEmpty else {
            return 0.0
        }
        
        return 48.0
    }
    
    // MARK: `body`
    
    var body: some View {
        TabView {
            ExpandableMapView(style: .waypoint(detail: waypoint), isUserInteractionEnabled: false)
                .padding(.bottom, bottomPadding)
                              
            if let images = waypoint.locationDetail?.images {
                ForEach((0..<images.count), id: \.self) { index in
                    let imageData = images[index]
                    
                    image(for: imageData)
                        .aspectRatio(contentMode: .fit)
                        .ifLet(imageData.altText, if: {
                            $0.accessibilityLabel($1)
                                .accessibilityAddTraits(.isImage)
                        }, else: {
                            $0.accessibilityHidden(true)
                        })
                        .padding(.bottom, bottomPadding)
                }
            }
        }
        .tabViewStyle(.page)
    }
    
    // MARK: -
    
    @ViewBuilder
    private func image(for imageData: ActivityWaypointImage) -> some View {
        // !! `WebImage` does not appear to use the cached image, if one exists
        // Manually check for and present the cached image
        if let cacheKey = SDWebImageManager.shared.cacheKey(for: imageData.url), let image = SDImageCache.shared.imageFromCache(forKey: cacheKey) {
            // Present cached image
            Image(uiImage: image)
                .resizable()
        } else {
            // Image has not been cached
            WebImage(url: imageData.url, context: nil)
                .placeholder(Image("highlight-placeholder"))
                .resizable()
        }
    }
    
}

struct WaypointImageCarousel_Previews: PreviewProvider {
    
    static let userLocation = CLLocation(latitude: 47.640179, longitude: -122.111320)
    
    static let waypointLocation = CLLocation(latitude: 47.621901, longitude: -122.341150)
    
    static let images: [ActivityWaypointImage] = [
        ActivityWaypointImage(url: URL(string: "https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic")!, altText: "Description of photo")
    ]
    
    static let audio = [
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This audio belongs to a waypoint"),
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This is another audio clip for this waypoint."),
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This audio also belongs to a waypoint. This audio has a really really really really really really really really really really really really really really really really really really really long description so that I can test the multiline layout.")
    ]
    
    static let imported1 = ImportedLocationDetail(nickname: "Some Waypoint", annotation: "This is a description of the waypoint", images: nil, audio: audio)
    
    static let imported2 = ImportedLocationDetail(nickname: "Some Waypoint", annotation: "This is a description of the waypoint", images: images, audio: nil)
    
    static var route: RouteDetail {
        return RouteDetail(source: .database(id: ""), designData: .init(id: UUID().uuidString, name: "A Route", description: "A description", waypoints: [LocationDetail(location: waypointLocation, imported: imported1), LocationDetail(location: waypointLocation, imported: imported2)]))
    }
    
    static var previews: some View {
        VStack {
            WaypointImageCarousel(waypoint: WaypointDetail(index: 0, routeDetail: route))
                .linearGradientBackground(.darkBlue)
                .cornerRadius(5.0)
                .frame(height: 300.0)
                .padding(24.0)
            
            WaypointImageCarousel(waypoint: WaypointDetail(index: 1, routeDetail: route))
                .linearGradientBackground(.darkBlue)
                .cornerRadius(5.0)
                .frame(height: 300.0)
                .padding(24.0)
        }
        .frame(maxHeight: .infinity)
        .background(Color.quaternaryBackground.ignoresSafeArea())
    }
    
}
