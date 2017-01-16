//
//  StarView.swift
//  Candy-Machine
//
//  Created by Nicholas Bourdakos on 1/15/17.
//  Copyright © 2017 Nicholas Bourdakos. All rights reserved.
//

import UIKit

@IBDesignable class StarView: UIView {
    var amplitude: CGFloat = 0.05
    var newAmplitude: CGFloat = 0.05
    
    let shapeLayer = CAShapeLayer()
    let maskLayer = CAShapeLayer()
    var rectanglePath = UIBezierPath()
    
    @IBInspectable var color: UIColor! = UIColor.red
    @IBInspectable var duration: Double = 3.0
    
    override func awakeFromNib() {
        // Drawing code
        backgroundColor = UIColor.clear
        
        // initial shape of the view
        rectanglePath = parametricPath(in: bounds, count: 50, function: circleWave)
        
        // Create initial shape of the view
        shapeLayer.path = rectanglePath.cgPath
        shapeLayer.fillColor = color.cgColor
        layer.addSublayer(shapeLayer)
        
        //mask layer
        maskLayer.path = shapeLayer.path
        maskLayer.position =  shapeLayer.position
        layer.mask = maskLayer
        rotate360Degrees()
    }
    
    private func rotate360Degrees() {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        self.layer.add(rotateAnimation, forKey: nil)
    }
    
    func setPulse(amplitude: CGFloat) {
        newAmplitude = amplitude
        
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            self.collapse()
        })
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.5
        
        // Your new shape here
        animation.toValue = parametricPath(in: bounds, count: 50, function: newCircleWave).cgPath
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        // The next two line preserves the final shape of animation,
        // if you remove it the shape will return to the original shape after the animation finished
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        shapeLayer.add(animation, forKey: nil)
        maskLayer.add(animation, forKey: nil)
        CATransaction.commit()
    }
    
    private func collapse() {
        newAmplitude = 0.01
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 1
        
        // Your new shape here
        animation.toValue = parametricPath(in: bounds, count: 50, function: newCircleWave).cgPath
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        // The next two line preserves the final shape of animation,
        // if you remove it the shape will return to the original shape after the animation finished
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        shapeLayer.add(animation, forKey: nil)
        maskLayer.add(animation, forKey: nil)
    }
    
    private func newCircleWave(t: CGFloat) -> (CGPoint) {
        return CGPoint(
            x: (0.4 + newAmplitude * cos(6 * t)) * cos(t) + 0.5,
            y: (0.4 + newAmplitude * cos(6 * t)) * sin(t) + 0.5
        )
    }
    
    private func circleWave(t: CGFloat) -> (CGPoint) {
        return CGPoint(
            x: (0.4 + amplitude * cos(6 * t)) * cos(t) + 0.5,
            y: (0.4 + amplitude * cos(6 * t)) * sin(t) + 0.5
        )
    }
    
    private func parametricPath(in rect: CGRect, count: Int? = nil, function: (CGFloat) -> (CGPoint)) -> UIBezierPath {
        let numberOfPoints = count ?? max(Int(rect.size.width), Int(rect.size.height))
        
        let path = UIBezierPath()
        let result = function(-10)
        path.move(to: convert(point: CGPoint(x: result.x, y: result.y), in: rect))
        for i in -10 * numberOfPoints + 1 ..< 11 * numberOfPoints {
            let t = CGFloat(i) / CGFloat(numberOfPoints - 1)
            let result = function(t)
            path.addLine(to: convert(point: CGPoint(x: result.x, y: result.y), in: rect))
        }
        return path
    }
    
    private func convert(point: CGPoint, in rect: CGRect) -> CGPoint {
        return CGPoint(
            x: rect.origin.x + point.x * rect.size.width,
            y: rect.origin.y + rect.size.height - point.y * rect.size.height
        )
    }
}
