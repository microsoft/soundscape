//
//  GeometryPreferenceReader.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct GeometryPreferenceReader<K: PreferenceKey, V> where K.Value == V {
    let key: K.Type
    let value: (GeometryProxy) -> V
}

extension GeometryPreferenceReader: ViewModifier {
    func body(content: Content) -> some View {
        // Use a clear background with a geometry reader to set a provided preference key with a selected geometry value
        content.background(GeometryReader {
            Color.clear.preference(key: self.key, value: self.value($0))
        })
    }
}

extension View {
    func readGeometryPreference<K: PreferenceKey, V: Equatable>(key: K.Type, value: @escaping (GeometryProxy) -> V) -> some View where K.Value == V {
        modifier(GeometryPreferenceReader<K, V>(key: key, value: value))
    }
}
