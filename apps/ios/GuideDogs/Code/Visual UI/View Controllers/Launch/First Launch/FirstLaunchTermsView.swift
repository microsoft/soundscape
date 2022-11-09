//
//  FirstLaunchTermsView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct FirstLaunchTermsView: UIViewControllerRepresentable {
    
    // MARK: Properties
    
    let onTermsAccepted: () -> Void
    
    // MARK: `UIViewControllerRepresentable`
    
    class Coordinator: FirstLaunchTermsStepDelegate {
        let handler: () -> Void
        
        init(onTermsAccepted: @escaping () -> Void) {
            handler = onTermsAccepted
        }
        
        func onTermsAccepted() {
            handler()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTermsAccepted: onTermsAccepted)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "FirstLaunch", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "termsFirstLaunchViewController") as! FirstLaunchTermsStepViewController
        
        vc.delegate = context.coordinator
        vc.view.backgroundColor = .clear
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
    
}
