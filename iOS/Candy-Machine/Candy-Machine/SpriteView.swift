//
//  SpriteView.swift
//  Candy-Machine
//
//  Created by Nicholas Bourdakos on 1/16/17.
//  Copyright © 2017 Nicholas Bourdakos. All rights reserved.
//

import SpriteKit
import AudioKit

class SpriteView: SKScene {
    var amplitudeTracker: AKAmplitudeTracker!
    
    let player0 = SKSpriteNode(imageNamed: "red.png")
    let player1 = SKSpriteNode(imageNamed: "green.png")
    let player2 = SKSpriteNode(imageNamed: "blue.png")
    
    var player = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        player0.position = CGPoint(x: size.width/2, y: size.height/2)
        player0.size = CGSize(width: player0.size.width * 0.5, height: player0.size.height * 0.5)
        player0.blendMode = SKBlendMode.screen
        addChild(player0)
        
        player1.position = CGPoint(x: size.width/2, y: size.height/2)
        player1.size = CGSize(width: player1.size.width * 0.5, height: player1.size.height * 0.5)
        player1.blendMode = SKBlendMode.screen
        addChild(player1)
    
        player2.position = CGPoint(x: size.width/2, y: size.height/2)
        player2.size = CGSize(width: player2.size.width * 0.5, height: player2.size.height * 0.5)
        player2.blendMode = SKBlendMode.screen
        addChild(player2)
        
        let angle: CGFloat = CGFloat(M_PI)
        let rotate = SKAction.rotate(byAngle: angle, duration: 3)
        let repeatAction = SKAction.repeatForever(rotate)
        player0.run(repeatAction, withKey: "rotate")
        
        let angle2: CGFloat = CGFloat(2 * M_PI)
        let rotate2 = SKAction.rotate(byAngle: angle2, duration: 3)
        let repeatAction2 = SKAction.repeatForever(rotate2)
        player1.run(repeatAction2, withKey: "rotate")
        
        let angle3: CGFloat = CGFloat(3 * M_PI)
        let rotate3 = SKAction.rotate(byAngle: angle3, duration: 3)
        let repeatAction3 = SKAction.repeatForever(rotate3)
        player2.run(repeatAction3, withKey: "rotate")
        
        let mic = AKMicrophone()
        amplitudeTracker = AKAmplitudeTracker(mic)
        AKSettings.audioInputEnabled = true
        AudioKit.output = amplitudeTracker
        AudioKit.start()
        mic.start()
        amplitudeTracker.start()
        
        AKPlaygroundLoop(every: 0.1) {
//            print("do not delete - this is a hack")
            let amp =  self.ampToSize(amp: self.amplitudeTracker.amplitude)
            
            if self.player == 0 {
                self.boost(player: self.player0, height: amp)
                self.boost(player: self.player1, height: amp * 0.8)
                self.boost(player: self.player2, height: amp * 0.8)
            } else if self.player == 1 {
                self.boost(player: self.player1, height: amp)
                self.boost(player: self.player0, height: amp * 0.8)
                self.boost(player: self.player2, height: amp * 0.8)
            } else {
                self.boost(player: self.player2, height: amp)
                self.boost(player: self.player0, height: amp * 0.8)
                self.boost(player: self.player1, height: amp * 0.8)
                self.player = -1
            }
            self.player += 1
        }
    }
    
    func ampToSize(amp: Double) -> CGFloat {
        return CGFloat(min(amp / 0.08 * 400, 400))
    }
    
    func boost(player: SKSpriteNode, height: CGFloat) {
        if (player.size.height < height) {
            let size = SKAction.resize(toHeight: height, duration: 0.1)
            player.run(size, completion: {
                let size = SKAction.resize(toHeight: 200, duration: 0.6)
                player.run(size)
            })
        }
    }
}
