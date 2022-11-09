//
//  NavigationButton.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct NavigationButton<Label: View, Destination: View>: View {
    
    // MARK: Properties
    
    @State private var isActive = false
    
    private let label: Label
    private let destination: Destination
        
    // MARK: Initialization
    
    init(title: String, destination: Destination) where Label == Text {
        self.destination = destination
        self.label = Text(title)
    }
    
    init(destination: Destination, label: () -> Label) {
        self.destination = destination
        self.label = label()
    }
    
    // MARK: `body`
    
    var body: some View {
        ZStack {
            NavigationLink(
                destination: destination,
                isActive: $isActive,
                label: {
                    EmptyView()
                })
                .accessibility(hidden: true)
                .hidden()
            
            Button(action: {
                self.isActive = true
            }, label: {
                label
            })
        }
    }
    
}

struct NavigationButton_Previews: PreviewProvider {
    
    static var previews: some View {
        
        NavigationView {
            NavigationButton(title: "Press Me!", destination: Text("Hello World."))
        }
        
        NavigationView {
            NavigationButton(destination: Text("Hello World.")) {
                Text("Press Me Too!")
            }
        }
        
    }
    
}
