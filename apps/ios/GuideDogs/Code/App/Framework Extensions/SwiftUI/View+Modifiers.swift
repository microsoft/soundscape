//
//  View+Modifiers.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

extension View {
    
    func accessibleTextFormat() -> some View {
        modifier(AccessibleTextFormat())
    }
    
    func locationNameTextFormat() -> some View {
        modifier(LocationNameTextFormat())
    }
    
    func locationDistanceTextFormat() -> some View {
        modifier(LocationDistanceTextFormat())
    }
    
    func locationAddressTextFormat() -> some View {
        modifier(LocationAddressTextFormat())
    }
    
}
