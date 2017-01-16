//
//  StarBoy.swift
//  Candy-Machine
//
//  Created by Nicholas Bourdakos on 1/15/17.
//  Copyright © 2017 Nicholas Bourdakos. All rights reserved.
//

import UIKit

class StarBoy: UIView {
    var layer0 = UIImage(named:"red.png")!
    var layer1 = UIImage(named:"green.png")!
    var layer2 = UIImage(named:"blue.png")!

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        backgroundColor = UIColor.clear
        
        layer0 = layer0.imageRotatedBy(deg: 10)
        layer0.draw(in: rect, blendMode: .screen, alpha: 1)

//        layer1 = layer1.imageRotatedBy(deg: 20)
//        layer1.draw(in: rect, blendMode: .screen, alpha: 1)
//
//        layer2 = layer2.imageRotatedBy(deg: 8)
//        layer2.draw(in: rect, blendMode: .screen, alpha: 1)
        displayLink.isPaused = false
//        rotate360Degrees()
    }
    
    private lazy var displayLink : CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(StarBoy.update))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        return displayLink
    }()
    
    func update() {
        setNeedsDisplay()
    }

    
//    private func rotate360Degrees() {
//        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
//        rotateAnimation.fromValue = 0.0
//        rotateAnimation.toValue = CGFloat(M_PI * 2)
//        rotateAnimation.isRemovedOnCompletion = false
//        rotateAnimation.duration = 3
//        rotateAnimation.repeatCount = Float.infinity
//        self.layer.add(rotateAnimation, forKey: nil)
//    }
}

extension UIImage {
    func imageRotatedBy(deg degrees: CGFloat) -> UIImage {
        let size = self.size
        
        UIGraphicsBeginImageContext(size)
        
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: size.width / 2, y: size.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat(M_PI / 180)))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        
        let origin = CGPoint(x: -size.width / 2, y: -size.width / 2)
        
        bitmap.draw(self.cgImage!, in: CGRect(origin: origin, size: size))
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
