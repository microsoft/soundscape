//
//  ModalNavigationView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct ModalNavigationView: ViewModifier {
    
    // MARK: Properties
    
    @Binding private var isPresented: Bool
    
    private let style: NavigationBarStyle
    private let dismissHandler: (() -> Void)?
    
    // MARK: Initialization
    
    init(isPresented: Binding<Bool>, style: NavigationBarStyle) {
        _isPresented = isPresented
        self.style = style
        self.dismissHandler = nil
    }
    
    init(style: NavigationBarStyle, dismissHandler: @escaping () -> Void) {
        _isPresented = .constant(true)
        self.style = style
        self.dismissHandler = dismissHandler
    }
    
    // MARK: `body`
    
    func body(content: Content) -> some View {
        NavigationView {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarStyle(style: style)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isPresented = false
                            dismissHandler?()
                        } label: {
                            GDLocalizedTextView("general.alert.close")
                        }
                        .foregroundColor(style.foregroundColor)
                    }
                }
        }
        .accessibilityIgnoresInvertColors(true)
    }
    
}

extension View {
    
    func asModalNavigationView(isPresented: Binding<Bool>, style: NavigationBarStyle = .darkBlue) -> some View {
        modifier(ModalNavigationView(isPresented: isPresented, style: style))
    }
    
    func asModalNavigationView(style: NavigationBarStyle = .darkBlue, dismissHandler: @escaping () -> Void) -> some View {
        modifier(ModalNavigationView(style: style, dismissHandler: dismissHandler))
    }
    
}
