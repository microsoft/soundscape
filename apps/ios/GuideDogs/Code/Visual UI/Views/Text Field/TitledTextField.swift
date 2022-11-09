//
//  TitledTextField.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct TitledTextField: View {
    
    // MARK: Properties
    
    @Environment(\.colorPalette) var colorPalette
    
    let title: String
    let defaultValue: String?
    
    @Binding var value: String
    
    private var accessibilityLabel: String {
        if value.isEmpty, let defaultValue = defaultValue {
            return GDLocalizedString("directions.name_distance", title, defaultValue)
        } else {
            return title
        }
    }
    
    // MARK: Initialization
    
    init(title: String, defaultValue: String, value: Binding<String>) {
        // Initialize labels
        self.title = title
        self.defaultValue = defaultValue
        
        // Initialize value binding
        _value = value
    }
    
    init(field: TitleTextFieldItem, value: Binding<String>) {
        // Initialize the view with a known field
        title = field.title
        defaultValue = field.defaultValue
        
        // Initialize value binding
        _value = value
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(title)
                .foregroundColor(colorPalette.light)
                .font(.callout)
                // Include title and default value with the `TextField` element
                .accessibilityHidden(true)
            
            TextField("", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel(accessibilityLabel)
            
            if let defaultValue = defaultValue {
                Text(defaultValue)
                    .foregroundColor(Color.Theme.lightGray)
                    .font(.subheadline)
                    // Include title and default value with the `TextField` element
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
}

struct RouteEditForm_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack(spacing: 18.0) {
            TitledTextField(title: "Name", defaultValue: "My Route", value: .constant(""))
            
            TitledTextField(title: "Name", defaultValue: "My Route", value: .constant("This is a Route"))
        }
        .background(Color.tertiaryBackground)
        .colorPalette(Palette.Theme.teal)
    }
    
}
