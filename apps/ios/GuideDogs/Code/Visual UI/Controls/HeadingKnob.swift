//
//  HeadingKnob.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class HeadingKnob: UIControl {

    private let renderer = HeadingKnobRenderer()

    var lineWidth: CGFloat {
        get { return renderer.lineWidth }
        set { renderer.lineWidth = newValue }
    }
    
    var startAngle: CGFloat {
        get { return renderer.startAngle }
        set { renderer.startAngle = newValue }
    }
    
    var endAngle: CGFloat {
        get { return renderer.endAngle }
        set { renderer.endAngle = newValue }
    }
    
    var pointerLength: CGFloat {
        get { return renderer.pointerLength }
        set { renderer.pointerLength = newValue }
    }
    
    var minimumValue: Float = 0
    
    var maximumValue: Float = 360
    
    private (set) var value: Float = 0
    
    func setValue(_ newValue: Float, animated: Bool = false) {
        value = min(maximumValue, max(minimumValue, newValue))
        
        let angleRange = endAngle - startAngle
        let valueRange = maximumValue - minimumValue
        let angleValue = CGFloat(value - minimumValue) / CGFloat(valueRange) * angleRange + startAngle
        
        // Note: don't animate if we are wrapping around the circle
        renderer.setPointerAngle(angleValue, animated: animated && (Double(abs(angleValue - renderer.pointerAngle)) * (180.0 / Double.pi)) < 180.0)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        renderer.updateBounds(bounds)
        renderer.trackColor = .white
        renderer.sliderColor = Colors.Background.quaternary ?? .black
        renderer.tint = tintColor
        renderer.lineWidth = 4
        renderer.setPointerAngle(renderer.startAngle, animated: false)
        
        layer.addSublayer(renderer.trackLayer)
        layer.addSublayer(renderer.pointerLayer)
        layer.addSublayer(renderer.sliderLayer)
        
        let gestureRecognizer = RotationGestureRecognizer(target: self, action: #selector(HeadingKnob.handleGesture(_:)))
        addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleGesture(_ gesture: RotationGestureRecognizer) {
        let angleRange = endAngle - startAngle
        let valueRange = maximumValue - minimumValue
        let angleValue = Float(gesture.touchAngle - startAngle) / Float(angleRange) * valueRange + minimumValue
        
        setValue(fmod(angleValue + 360, 360))
        
        sendActions(for: .valueChanged)
    }

}

private class HeadingKnobRenderer {
    var trackColor: UIColor = .white {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
            pointerLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var sliderColor: UIColor = Colors.Background.quaternary ?? .black {
        didSet {
            sliderLayer.strokeColor = sliderColor.cgColor
        }
    }
    
    var tint: UIColor = Colors.Foreground.secondary ?? .white {
        didSet {
            sliderLayer.fillColor = tint.cgColor
        }
    }
    
    var lineWidth: CGFloat = 6 {
        didSet {
            trackLayer.lineWidth = lineWidth
            pointerLayer.lineWidth = lineWidth
            sliderLayer.lineWidth = lineWidth
            updateTrackLayerPath()
            updatePointerLayerPath()
            updateSliderLayerPath()
        }
    }
    
    var startAngle: CGFloat = CGFloat(Double.pi) * -1 / 2 {
        didSet {
            updateTrackLayerPath()
        }
    }
    
    var endAngle: CGFloat = CGFloat(Double.pi) * 3 / 2 {
        didSet {
            updateTrackLayerPath()
        }
    }
    
    var pointerLength: CGFloat = 10 {
        didSet {
            updateTrackLayerPath()
            updatePointerLayerPath()
            updateSliderLayerPath()
        }
    }
    
    private (set) var pointerAngle: CGFloat = CGFloat(-Double.pi) / 2
    
    func setPointerAngle(_ newPointerAngle: CGFloat, animated: Bool = false) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        sliderLayer.transform = CATransform3DMakeRotation(newPointerAngle, 0, 0, 1)
        
        if animated {
            let midAngleValue = (max(newPointerAngle, pointerAngle) - min(newPointerAngle, pointerAngle)) / 2
                + min(newPointerAngle, pointerAngle)
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.values = [pointerAngle, midAngleValue, newPointerAngle]
            animation.keyTimes = [0.0, 0.5, 1.0]
            animation.timingFunctions = [CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)]
            sliderLayer.add(animation, forKey: nil)
        }
        
        CATransaction.commit()
        
        pointerAngle = newPointerAngle
    }
    
    let trackLayer = CAShapeLayer()
    let pointerLayer = CAShapeLayer()
    let sliderLayer = CAShapeLayer()
    
    init() {
        trackLayer.fillColor = UIColor.clear.cgColor
        pointerLayer.fillColor = UIColor.clear.cgColor
        sliderLayer.fillColor = UIColor.clear.cgColor
    }

    private func updateTrackLayerPath() {
        let bounds = trackLayer.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let offset = max(pointerLength, lineWidth  / 2)
        let radius = min(bounds.width, bounds.height) / 2 - offset
        
        let ring = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle,
                                endAngle: endAngle, clockwise: true)
        trackLayer.path = ring.cgPath
    }
    
    private func updatePointerLayerPath() {
        let bounds = trackLayer.bounds
        
        let pointer = UIBezierPath()
        let cgPointerLength = CGFloat(pointerLength)
        let cgHalfLineWidth = CGFloat(lineWidth) / 2
        
        // East
        pointer.move(to: CGPoint(x: bounds.width - cgPointerLength - cgHalfLineWidth, y: bounds.midY))
        pointer.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        
        // North
        pointer.move(to: CGPoint(x: bounds.midX, y: cgPointerLength + cgHalfLineWidth))
        pointer.addLine(to: CGPoint(x: bounds.midX, y: 0))
        
        // West
        pointer.move(to: CGPoint(x: cgPointerLength + cgHalfLineWidth, y: bounds.midY))
        pointer.addLine(to: CGPoint(x: 0, y: bounds.midY))
        
        // South
        pointer.move(to: CGPoint(x: bounds.midX, y: bounds.height - cgPointerLength - cgHalfLineWidth))
        pointer.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
        
        pointerLayer.path = pointer.cgPath
    }
    
    private func updateSliderLayerPath() {
        let bounds = trackLayer.bounds
        
        let slider = UIBezierPath()
        let cgPointerLength = CGFloat(pointerLength)
        let cgRadius = cgPointerLength - CGFloat(lineWidth)
        let center = CGPoint(x: bounds.width - cgPointerLength, y: bounds.midY)
        
        slider.addArc(withCenter: center, radius: cgRadius, startAngle: 0, endAngle: CGFloat(Double.pi) * 2, clockwise: true)
        
        sliderLayer.path = slider.cgPath
    }
    
    func updateBounds(_ bounds: CGRect) {
        trackLayer.bounds = bounds
        trackLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        updateTrackLayerPath()
        
        pointerLayer.bounds = trackLayer.bounds
        pointerLayer.position = trackLayer.position
        updatePointerLayerPath()
        
        sliderLayer.bounds = trackLayer.bounds
        sliderLayer.position = trackLayer.position
        updateSliderLayerPath()
    }

}

private class RotationGestureRecognizer: UIPanGestureRecognizer {
    private(set) var touchAngle: CGFloat = 0
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        maximumNumberOfTouches = 1
        minimumNumberOfTouches = 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        updateAngle(with: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        updateAngle(with: touches)
    }
    
    private func updateAngle(with touches: Set<UITouch>) {
        guard
            let touch = touches.first,
            let view = view
            else {
                return
        }
        let touchPoint = touch.location(in: view)
        touchAngle = angle(for: touchPoint, in: view)
    }
    
    private func angle(for point: CGPoint, in view: UIView) -> CGFloat {
        let centerOffset = CGPoint(x: point.x - view.bounds.midX, y: point.y - view.bounds.midY)
        return atan2(centerOffset.y, centerOffset.x)
    }

}
