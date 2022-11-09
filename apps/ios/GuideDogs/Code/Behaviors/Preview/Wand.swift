//
//  Wand.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol WandDelegate: AnyObject {
    func wandDidStart(_ wand: Wand)
    func wand(_ wand: Wand, didCrossThreshold target: Orientable)
    func wand(_ wand: Wand, didGainFocus target: Orientable, isInitial: Bool)
    func wand(_ wand: Wand, didLongFocus target: Orientable)
    func wand(_ wand: Wand, didLoseFocus target: Orientable)
}

protocol Wand {
    var delegate: WandDelegate? { get set }
    
    func start(with: [WandTarget], heading: HeadingNotifier)
    func stop()
}
