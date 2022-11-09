//
//  PreferenceKeyHelpers.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

/// This phantom type is used for preventing repetition of code for PreferenceKey types
protocol Preference {}

/// A preference key
struct MaxValue<T: Preference, V: Numeric & Comparable>: PreferenceKey {
    static var defaultValue: V { V.zero }
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
    
    typealias Value = V
}

extension View {
    func assignPreference<K: PreferenceKey, V: Equatable>(for key: K.Type, to binding: Binding<V?>) -> some View where K.Value == V {
        return self.onPreferenceChange(key.self) { max in
            binding.wrappedValue = max
        }
    }
}
