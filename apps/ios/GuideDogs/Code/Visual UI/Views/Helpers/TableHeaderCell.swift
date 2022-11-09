//
//  TableHeaderCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct TableHeaderCell: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(text.localizedUppercase)
                .font(.caption)
                .foregroundColor(.primaryForeground)
                .accessibilityAddTraits([.isHeader])
                .padding([.leading, .trailing, .top])
                .padding([.bottom], 6)
            
            Spacer()
        }
        .background(Color.quaternaryBackground)
    }
}

struct TableHeaderCell_Previews: PreviewProvider {
    static var previews: some View {
        TableHeaderCell(text: "Test")
    }
}
