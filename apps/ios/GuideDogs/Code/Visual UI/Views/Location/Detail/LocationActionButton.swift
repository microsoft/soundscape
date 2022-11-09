//
//  LocationDetailButton.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LocationActionButton: View {
    
    // MARK: Properties
    
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 24.0
    
    let action: LocationAction
    let handler: () -> Void
    
    // MARK: `body`
    
    var body: some View {
        Button {
            handler()
        } label: {
            HStack(spacing: 8.0) {
                if let image = action.image {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: imageSize, height: imageSize)
                        .accessibilityHidden(true)
                }
                
                Text(action.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8.0)
        }
        .disabled(action.isEnabled == false)
        // Disabled appearance
        .if(action.isEnabled == false, transform: { $0.opacity(0.4) })
        .ifLet(action.accessibilityHint, transform: { $0.accessibilityHint($1) })
        .ifLet(action.accessibilityIdentifier, transform: { $0.accessibilityIdentifier($1) })
    }
    
}

struct LocationActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0.0) {
            LocationActionButton(action: .beacon) {
                // no-op
            }
            
            LocationActionButton(action: .save(isEnabled: true)) {
                // no-op
            }
            
            LocationActionButton(action: .save(isEnabled: false)) {
                // no-op
            }
            
            LocationActionButton(action: .edit) {
                // no-op
            }
            
            LocationActionButton(action: .preview) {
                // no-op
            }
            
            LocationActionButton(action: .share(isEnabled: true)) {
                // no-op
            }
            
            LocationActionButton(action: .share(isEnabled: false)) {
                // no-op
            }
        }
        .background(Color.tertiaryBackground)
        .foregroundColor(Color.primaryForeground)
    }
}
