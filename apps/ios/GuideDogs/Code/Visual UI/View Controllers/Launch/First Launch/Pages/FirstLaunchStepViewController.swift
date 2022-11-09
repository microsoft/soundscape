//
//  FirstLaunchPageViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class FirstLaunchStepViewController: UIViewController {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var body: UILabel!
    
    var voiceOverDescription: String {
        let headerStr = header.accessibilityLabel ?? header.text ?? ""
        let bodyStr = body.accessibilityLabel ?? body.text ?? ""
        return "\(headerStr). \(bodyStr)"
    }
    
}
