//
//  TitledText.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct TitledText: View {
    
    // MARK: Properties
    
    let title: String
    let text: String
    
    // MARK: `body`
    
    var body: some View {
        VStack(spacing: 4.0) {
            Text(title)
                .font(.callout.smallCaps())
                .opacity(0.90)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
    
}

struct TitledText_Previews: PreviewProvider {
    static var previews: some View {
        TitledText(title: "A Heading", text: "Some content")
            .padding(12.0)
            .foregroundColor(Color.white)
            .background(Color.secondaryBackground)
    }
}
