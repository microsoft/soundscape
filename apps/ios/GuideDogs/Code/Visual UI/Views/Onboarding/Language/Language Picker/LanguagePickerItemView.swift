//
//  LanguagePickerItemView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LanguagePickerItemView: View {
    
    // MARK: Properties
    
    let locale: Locale
    let isSelected: Bool
    let appLocale: Locale
    private let dividerColor: Color?
    
    private var title: String {
        return locale.localizedDescription
    }
    
    private var subtitle: String {
        return locale.localizedDescription(with: appLocale)
    }
    
    // MARK: Initialization
    
    init(locale: Locale, isSelected: Bool, appLocale: Locale) {
        self.locale = locale
        self.isSelected = isSelected
        self.appLocale = appLocale
        // Use default value
        self.dividerColor = nil
    }
    
    private init(locale: Locale, isSelected: Bool, appLocale: Locale, dividerColor: Color) {
        self.locale = locale
        self.isSelected = isSelected
        self.appLocale = appLocale
        self.dividerColor = dividerColor
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 12.0) {
                Image(systemName: "checkmark")
                    .if(!isSelected, transform: { $0.hidden() })
                    .accessibility(hidden: true)
                
                VStack(spacing: 4.0) {
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.center)
                        .accessibleTextFormat()
                        .accessibilityLabel(isSelected ? GDLocalizedString("filter.selected", locale.localizedDescription) : locale.localizedDescription)
                    
                    Text(subtitle)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.center)
                        .accessibleTextFormat()
                        .accessibilityHidden(subtitle == title)
                }
            }
            .padding(.horizontal, 18.0)
            .padding(.vertical, 12.0)
            
            Divider()
                .background(dividerColor)
                .padding(.horizontal, 8.0)
        }
        .accessibilityElement(children: .combine)
    }
    
}

struct LanguagePickerItemView_Previews: PreviewProvider {
    
    static var locale1 = Locale(identifier: "en_US")
    static var locale2 = Locale(identifier: "es_ES")
    static var locale3 = Locale(identifier: "en_GB")
    static var locale4 = Locale(identifier: "ja_JP")
    
    static var previews: some View {
        ZStack {
            VStack(spacing: 0.0) {
                // Selected item
                LanguagePickerItemView(locale: locale1, isSelected: true, appLocale: locale1)
                    .background(Color.primaryForeground)
                    .foregroundColor(Color.primaryBackground)
                
                // Selected item
                // Item and app locales: same language, different region
                LanguagePickerItemView(locale: locale1, isSelected: true, appLocale: locale3)
                    .background(Color.primaryForeground)
                    .foregroundColor(Color.primaryBackground)
                
                // Item is not selected
                // Item and app locales are different
                LanguagePickerItemView(locale: locale4, isSelected: false, appLocale: locale1)
                    .background(Color.primaryForeground)
                    .foregroundColor(Color.primaryBackground)
                
                // Item is not selected
                // Item and app locales are different
                // Try different colors
                LanguagePickerItemView(locale: locale2, isSelected: false, appLocale: locale1)
                    .dividerColor(.greenHighlight)
                    .linearGradientBackground(.blue)
                    .foregroundColor(Color.primaryForeground)
            }
            .cornerRadius(5.0)
            .padding(24.0)
        }
        .linearGradientBackground(.purple, ignoresSafeArea: true)
    }
    
}

extension LanguagePickerItemView {
    
    func dividerColor(_ dividerColor: Color) -> some View {
        LanguagePickerItemView(locale: self.locale, isSelected: self.isSelected, appLocale: self.appLocale, dividerColor: dividerColor)
    }
    
}
