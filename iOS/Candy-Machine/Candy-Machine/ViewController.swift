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
            if self.speechText != "" {
                self.speech.text = self.speechText
            } else {
                self.speech.text = "Listening..."
            }
            print("rec")
        }
    }
    
    func stopStreaming() {
        speechToText.stopRecognizeMicrophone()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            print("requesting: \(self.speechText)")
            var request = URLRequest(url: URL(string: "https://candy-machine.mybluemix.net/sentiment")!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let postString = "transcript=" + self.speechText
            request.httpBody = postString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    DispatchQueue.main.async() {
                        self.speech.text = "Try again"
                    }
                } else {
                    do {
                        let parsedData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                        DispatchQueue.main.async() {
                            self.speech.text = String(describing: parsedData["sentiment"] ?? "Try again")
                        }
                    } catch _ as NSError {
                        DispatchQueue.main.async() {
                            self.speech.text = "Try again"
                        }
                    }
                }
            }
            task.resume()
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = SpriteView(size: view.bounds.size)
        let skView = view as! SKView
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        
        record.addTarget(self, action: #selector(ViewController.buttonDown(sender:)), for: .touchDown)
        record.addTarget(self, action: #selector(ViewController.buttonUp(sender:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    func buttonDown(sender: AnyObject) {
        startStreaming()
        speech.text = "Listening..."
    }
    
    func buttonUp(sender: AnyObject) {
        stopStreaming()
    }

}

