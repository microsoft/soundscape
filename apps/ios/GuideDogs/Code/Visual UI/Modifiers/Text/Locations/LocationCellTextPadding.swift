//
//  LocationCellTextPadding.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LocationCellTextPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding([.top, .bottom], 12)
            .padding([.leading], 20.0)
    }
}

extension View {
    func locationCellTextPadding() -> some View {
        modifier(LocationCellTextPadding())
    }
}
