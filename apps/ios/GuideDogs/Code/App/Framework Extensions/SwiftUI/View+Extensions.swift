//
//  View+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

extension View {
    
    ///
    /// Applies the given transformation if the given condition is `true`
    ///
    /// Parameters
    /// - condition: boolean indicating whether the given transformation is applied
    /// - transform: closure that applies the transformation
    ///
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    ///
    /// Applies the given `if` transformation if the given condition is `true` and the given `else` transformation
    /// if the given condition is `false`
    ///
    /// Parameters
    /// - condition: boolean indicating which transformation is applied
    /// - ifTransform: closure that applies the transformation if the condition is `true`
    /// - elseTransform: closure that applies the transformation if the condition is `false`
    ///
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(_ condition: Bool, if ifTransform: (Self) -> TrueContent, else elseTransform: (Self) -> FalseContent) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    ///
    /// Applies the given transformation if the given value is not `nil`
    ///
    /// Parameters
    /// - value: value that is passed to the `if` transformation if it is not `nil`
    /// - transform: closure that applies the transformation if the given value is not `nil`
    ///
    @ViewBuilder
    func ifLet<V, Transform: View>(_ value: V?, transform: (Self, V) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    ///
    /// Applies the given `if` transformation if the given condition is `true` and the given `else` transformation
    /// if the given condition is `false`
    ///
    /// Parameters
    /// - value: value that is passed to the `if` transformation if it is not `nil`
    /// - ifTransform: closure that applies the transformation if the given value is not `nil`
    /// - elseTransform: closure that applies the transformation if given value is `nil`
    ///
    @ViewBuilder
    func ifLet<V, TrueContent: View, FalseContent: View>(_ value: V?, if ifTransform: (Self, V) -> TrueContent, else elseTransform: (Self) -> FalseContent) -> some View {
        if let value = value {
            ifTransform(self, value)
        } else {
            elseTransform(self)
        }
    }
    
    ///
    /// `hideKeyboard` can be used to hide the iOS keyboard for devices running iOS less than 15.0
    /// iOS 15.0 introduces `@FocusState` and the `.focused` modifier which can be used to dismiss
    /// `TextField` focus and the iOS keyboard
    ///
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}
