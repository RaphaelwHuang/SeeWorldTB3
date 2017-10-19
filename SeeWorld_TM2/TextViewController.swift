//
//  TextViewController.swift
//  SeeWorld_TM2
//
//  Created by Raphael on 9/25/17.
//  Copyright © 2017 RaphaelwHuang. All rights reserved.
//

import UIKit
import Speech
import Alamofire
import AVFoundation
import Foundation
import CoreLocation

class TextViewController: UIViewController, SFSpeechRecognizerDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    struct state {
        var boolClasS: Bool
        var waitReview: String = ""
        var waitDestination: String = ""
        var transMethodSelect: String = ""
    }
    
    // For speech
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var bestString = ""
    var input = " "
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // var weather = DataModel()
        microphoneButton.isEnabled = false
        speechRecognizer.delegate = self
        textView.isEditable = false
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    // Initial the microphone
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start", for: .normal)
            input = bestString

            self.claasify(input)
        } else {
            self.textView.text = "What can I help you with?"
            testToSpeech("What can I help you with?")
            // Delay the speech to text
             DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
                self.startRecording()
            }
            microphoneButton.setTitle("Stop", for: .normal)
        }
    }
    
    // Speech to Text
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.textView.text = result!.bestTranscription.formattedString
                
                self.bestString = result!.bestTranscription.formattedString
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    
    // NLC Func
    func claasify(_ input: String) {
        let apiEndpoint: String = "http://seeworld-api-test.mybluemix.net/seeworld/api/v1/natural-language-processing/classify";
        Alamofire.request(apiEndpoint, method: .get, parameters: ["input": input])
            .responseJSON { response in
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    print("error calling GET on /seeworld/api/v1/natural-language-processing/classify")
                    print(response.result.error!)
                    return
                }
                
                // make sure we got some JSON since that's what we expect
                guard let json = response.result.value as? [String: Any] else {
                    print("didn't get classify object as JSON from API")
                    print("Error: \(String(describing: response.result.error))")
                    return
                }
                
                // get and print the title
                guard let classifiedResult = json["value"] as? String else {
                    print("Could not get classified result from JSON")
                    return
                }
                
                self.respondToClassifiedResult(classifiedResult)
        }
    }
    
  
    // Text to Speech
    func testToSpeech(_ outputText: String) {
        let utterance = AVSpeechUtterance(string: outputText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        let synVoice = AVSpeechSynthesizer()
        synVoice.speak(utterance)
    }
    
    // The Oupt Results by NLC
    func respondToClassifiedResult(_ classifiedResult: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapViewController = storyboard.instantiateViewController(withIdentifier :"MapViewController") as! MapViewController
        
        //self.textView.text.append("\n" + classifiedResult)
        switch classifiedResult {
        case "time":
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            let dateInFormat = dateFormatter.string(from: Date())
            self.textView.text = ("The time is " + dateInFormat)
            testToSpeech("The time is " + dateInFormat)
            break
            
        case "temperature":            
            self.textView.text = "It's Sunny outside, the temperature is 20 degree centigrade"

                //weather.getWeather(city: Columbus)
            testToSpeech("It's Sunny outside, the temperature is 20 degree centigrade")
            break
    
        // Open the Apple Map
        //根据你的NLC, 准备导航de的时候
        case "????":
            // Open Apple Map
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
                let myLocation = CLLocationCoordinate2D(latitude: mapViewController._latEnd, longitude: mapViewController._lonEnd)
                mapViewController.openInMapsTransit(coord: myLocation)
            }
            break
            
        default:
            // Get the ETA
            mapViewController.input = self.textView.text
            mapViewController.searchPlace(self.textView)
            break
        }
    }
    
}
