//
//  LoadingMarkersOrRoutesView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LoadingMarkersOrRoutesView: View {
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 64.0
    
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                
                Image("marker.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primaryForeground)
                    .frame(width: iconSize, height: iconSize)
                    .accessibility(hidden: true)
                
                Spacer()
            }
            
            GDLocalizedTextView("general.loading.loading")
                .font(.title)
                .lineLimit(nil)
                .foregroundColor(.primaryForeground)
                .padding([.top, .bottom], 16.0)
        }
        .padding([.leading, .trailing], 32.0)
        .padding([.top, .bottom], 64.0)
        .opacity(opacity)
        .onAppear {
            withAnimation(Animation.spring().delay(1.0)) {
                opacity = 1.0
            }
        }
    }
}

struct LoadingMarkersOrRoutesView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingMarkersOrRoutesView()
            .background(Color.quaternaryBackground)
    }
}
