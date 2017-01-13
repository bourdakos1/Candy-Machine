//
//  ViewController.swift
//  Candy-Machine
//
//  Created by Nicholas Bourdakos on 1/12/17.
//  Copyright © 2017 Nicholas Bourdakos. All rights reserved.
//

import UIKit
import SpeechToTextV1

class ViewController: UIViewController {
    
    @IBOutlet weak var speech: UILabel!
    @IBOutlet weak var record: UIButton!
    
    var speechToText: SpeechToText
    
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
            print(results.bestTranscript)
        }
    }
    
    func stopStreaming() {
        speechToText.stopRecognizeMicrophone()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        record.addTarget(self, action: #selector(ViewController.buttonDown(sender:)), for: .touchDown)
        record.addTarget(self, action: #selector(ViewController.buttonUp(sender:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    func buttonDown(sender: AnyObject) {
        startStreaming()
    }
    
    func buttonUp(sender: AnyObject) {
        stopStreaming()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

