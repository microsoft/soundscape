//
//  SortStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

enum SortStyle: String {
    case alphanumeric
    case distance
    
    func toggled() -> SortStyle {
        if self == .alphanumeric {
            return .distance
        } else {
            return .alphanumeric
        }
    }
}

struct SortStyleCell: View {
    let listName: String
    
    @Environment(\.sizeCategory) var sizeCategory
    @Binding var sort: SortStyle
    
    var text: String {
        if sort == .alphanumeric {
            return GDLocalizedString("markers.sort_button.sort_by_name")
        } else {
            return GDLocalizedString("markers.sort_button.sort_by_distance")
        }
    }
    
    var sortLabel: String {
        if sort == .alphanumeric {
            return GDLocalizedString("routes.sort.by_distance")
        } else {
            return GDLocalizedString("routes.sort.by_name")
        }
    }
    
    var voHint: Text {
        if sort == .alphanumeric {
            return GDLocalizedTextView("routes.sort.by_distance.hint")
        } else {
            return GDLocalizedTextView("routes.sort.by_name.hint")
        }
    }
    
    var voLabel: Text {
        if sort == .alphanumeric {
            return GDLocalizedTextView("markers.sort_button.sort_by_name.voiceover")
        } else {
            return GDLocalizedTextView("markers.sort_button.sort_by_distance.voiceover")
        }
    }
    
    @ViewBuilder private var cell: some View {
        if sizeCategory > .accessibilityLarge {
            VStack(alignment: .center) {
                Label(text, systemImage: "arrow.up.arrow.down")
                    .accessibility(label: voLabel)
                
                HStack {
                    Spacer()
                    
                    Button(sortLabel) {
                        sort = sort.toggled()
                        SettingsContext.shared.defaultMarkerSortStyle = sort
                    }
                    .foregroundColor(.secondaryForeground)
                    
                    Spacer()
                }
            }
        } else {
            HStack(alignment: .center) {
                Label(text, systemImage: "arrow.up.arrow.down")
                    .accessibility(label: voLabel)
                
                Spacer()
                
                Button(sortLabel) {
                    sort = sort.toggled()
                    SettingsContext.shared.defaultMarkerSortStyle = sort
                }
                .foregroundColor(.secondaryForeground)
            }
        }
    }
    
    var body: some View {
        cell.font(.subheadline)
            .foregroundColor(.primaryForeground)
            .padding([.leading, .trailing], 20)
            .padding([.top, .bottom], 8)
            .background(Color.tertiaryBackground)
            .accessibilityElement(children: .ignore)
            .accessibility(label: Text("\(listName).") + voLabel)
            .accessibility(hint: voHint)
            .accessibility(addTraits: [.isHeader, .isButton])
            .accessibilityAction {
                sort = sort.toggled()
                SettingsContext.shared.defaultMarkerSortStyle = sort
            }
    }
}
