//
//  MapViewControllerRepresentable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: UIViewControllerRepresentable {
    
    // MARK: Coordinator
    
    class Coordinator: MapViewControllerDelegate {
        
        private let handler: ((MKAnnotation) -> Void)?
        
        init(_ didSelectAnnotation: ((MKAnnotation) -> Void)?) {
            self.handler = didSelectAnnotation
        }
        
        func didSelectAnnotation(_ annotation: MKAnnotation) {
            handler?(annotation)
        }
        
    }
    
    // MARK: Properties
    
    let style: MapStyle
    private let didSelectAnnotation: ((MKAnnotation) -> Void)?
    
    // MARK: Initialization
    
    init(style: MapStyle, _ didSelectAnnotation: ((MKAnnotation) -> Void)?) {
        self.style = style
        self.didSelectAnnotation = didSelectAnnotation
    }
    
    // MARK: `UIViewControllerRepresentable`
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(didSelectAnnotation)
    }
    
    func makeUIViewController(context: Context) -> MapViewController {
        let storyboard = UIStoryboard(name: "Map", bundle: Bundle.main)
        let viewController = storyboard.instantiateViewController(identifier: "MapViewController") as! MapViewController
        
        viewController.style = style
        viewController.delegate = context.coordinator
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
    
}
