//
//  ViewController.swift
//  Candy-Machine
//
//  Created by Nicholas Bourdakos on 1/12/17.
//  Copyright © 2017 Nicholas Bourdakos. All rights reserved.
//

import UIKit
import SpeechToTextV1
import SpriteKit

class ViewController: UIViewController {
    
    @IBOutlet weak var speech: UILabel!
    @IBOutlet weak var record: UIButton!
//    @IBOutlet weak var star: StarView!
    
    var speechToText: SpeechToText
    var speechText = ""
    
    required init?(coder aDecoder: NSCoder) {
        var keys: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        let username = keys?["username"] as? String
        let password = keys?["password"] as? String
        
        // Initialize STT.
        speechToText = SpeechToText(username: username!, password: password!)    
        super.init(coder: aDecoder)
    }
    
    func startStreaming() {
        var settings = RecognitionSettings(contentType: .opus)
        settings.continuous = true
        settings.interimResults = true
        let failure = { (error: Error) in print(error) }
        speechToText.recognizeMicrophone(settings: settings, failure: failure) { results in
            self.speechText = results.bestTranscript
            print(self.speechText)
        }
    }
    
    func stopStreaming() {
        speechToText.stopRecognizeMicrophone()
        var request = URLRequest(url: URL(string: "https://candy-machine.mybluemix.net/sentiment")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let postString = "transcript=" + speechText
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
        }
        task.resume()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        record.addTarget(self, action: #selector(ViewController.buttonDown(sender:)), for: .touchDown)
        record.addTarget(self, action: #selector(ViewController.buttonUp(sender:)), for: [.touchUpInside, .touchUpOutside])
        
        let scene = SpriteView(size: view.bounds.size)
        let skView = view as! SKView
//        skView.showsFPS = true
//        skView.showsNodeCount = true
//        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    
    func buttonDown(sender: AnyObject) {
        startStreaming()
    }
    
    func buttonUp(sender: AnyObject) {
        stopStreaming()
    }
}

