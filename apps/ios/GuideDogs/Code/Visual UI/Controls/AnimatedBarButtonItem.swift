//
//  AnimatedBarButtonItem.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class AnimatedBarButtonItem: UIBarButtonItem {
    
    // MARK: Properties

    let imageView: UIImageView = UIImageView()
    
    open var animationImages: [UIImage]? {
        get {
            return imageView.animationImages
        }
        set(newAnimationImages) {
            imageView.animationImages = newAnimationImages
            updateImageViewSizeForImages(images: newAnimationImages)
        }
    }

    open var animationDuration: TimeInterval {
        get {
            return imageView.animationDuration
        }
        set(newAnimationDuration) {
            imageView.animationDuration = newAnimationDuration
        }
    }
    
    open var animationRepeatCount: Int {
        get {
            return imageView.animationRepeatCount
        }
        set(newAnimationRepeatCount) {
            imageView.animationRepeatCount = newAnimationRepeatCount
        }
    }
    
    open var isAnimating: Bool {
        return imageView.isAnimating
    }
    // MARK: Initializers

    init(animationImages: [UIImage]) {
        super.init()

        self.animationImages = animationImages
        self.customView = imageView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Convenience

    open func startAnimating() {
        imageView.startAnimating()
    }
    
    open func stopAnimating() {
        imageView.stopAnimating()
    }

    // MARK: Helpers

    private func updateImageViewSizeForImages(images: [UIImage]?) {
        guard let images = images else {
            return
        }
        
        guard !(images.isEmpty) else {
            return
        }
        
        let image: UIImage = images[0]
        imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    }
}
