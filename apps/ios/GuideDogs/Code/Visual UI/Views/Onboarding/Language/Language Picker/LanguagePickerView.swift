//
//  LanguagePickerView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LanguagePickerView: View {
    
    // MARK: Properties
    
    @Binding var selectedLocale: Locale
    
    let allLocales: [Locale]
    
    // MARK: Initialization
    
    init(selectedLocale: Binding<Locale>, allLocales: [Locale] = LocalizationContext.supportedLocales) {
        _selectedLocale = selectedLocale
        self.allLocales = allLocales
    }
    
    // MARK: `body`
    
    var body: some View {
        ZStack {
            Color.primaryForeground
            
            ScrollView {
                VStack(spacing: 0.0) {
                    // Standard beacons
                    ForEach(allLocales, id: \.self) { locale in
                        Button {
                            GDATelemetry.track("onboarding.language.selected", with: ["locale": locale.identifier])
                            
                            // Save app locale
                            LocalizationContext.currentAppLocale = locale
                            
                            // Save selected locale
                            selectedLocale = locale
                        } label: {
                            LanguagePickerItemView(locale: locale, isSelected: locale == selectedLocale, appLocale: selectedLocale)
                                .dividerColor(.primaryBackground)
                                .foregroundColor(.primaryBackground)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 400.0)
        .fixedSize(horizontal: false, vertical: true)
        .cornerRadius(5.0)
    }
    
}

struct LanguagePickerView_Previews: PreviewProvider {
    
    static let locales = [
        Locale(identifier: "en_US"),
        Locale(identifier: "en_GB"),
        Locale(identifier: "es_ES"),
        Locale(identifier: "ja_JP")
    ]
    
    static var previews: some View {
        OnboardingContainer {
            LanguagePickerView(selectedLocale: .constant(locales.first!), allLocales: locales)
        }
    }
    
}
