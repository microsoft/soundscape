//
//  ConfigurableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A UIViewController that can store a configuration callback block that
/// is called in viewWillAppear. This can be used to configure the content
/// of view controller outlets after the view has loaded.
class ConfigurableViewController: UIViewController {
    var configurator: ((UIViewController) -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configurator?(self)
    }
}
