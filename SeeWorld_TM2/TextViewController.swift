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
    var bool: Bool = true 
    var state = "sw_waiting_for_destination"

    // Initialize the var for speech fuction
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var bestString = ""
    var input = " "
    
    var lon: Double = 0.0
    var lat: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // var weather = DataModel()
        microphoneButton.isEnabled = false
        speechRecognizer.delegate = self
        textView.isEditable = false
        
        // Check the microphone
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
            // Make the button works
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    // The main func, which control the microphone
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start", for: .normal)
            input = bestString
            
            if (bool) {
                self.claasify(input, state)
            }
            else {
                state = "sw_trans_method_selection"
                self.claasify(input, state)
            }
        } else {
            if (bool) {
                self.textView.text = "What is your destination?"
                testToSpeech("What is your destination?")
            }
            else {
                self.textView.text = "Which transport do you prefer?"
                testToSpeech("Which transport do you prefer?")
            }

            // Delay the speech to text
             DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
                self.startRecording()
            }
            microphoneButton.setTitle("Stop", for: .normal)
        }
    }
    
    
    // NLC Func
    func claasify(_ input: String, _ state: String) {
        let apiEndpoint: String = "http://seeworld-api-test.mybluemix.net/seeworld/api/v1/natural-language-processing/classify";
        Alamofire.request(apiEndpoint, method: .get, parameters: ["input": input, "state": state])
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
    
    // NLC Func
    func getReview(_ input: String, _ state: String) {
        let apiEndpoint: String = " http://seeworld-api-test.mybluemix.net/seeworld/api/v1/user-reviews/get-insights";
        Alamofire.request(apiEndpoint, method: .get, parameters: ["input": input, "state": state])
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
    
    // The Oupt Results by NLC
    func respondToClassifiedResult(_ classifiedResult: String) {
        
        //Initial Map VC
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
            self.textView.text = "It's Sunny outside, the temperature is 22 degree centigrade"

                //weather.getWeather(city: Columbus)
            testToSpeech("It's Sunny outside, the temperature is 22 degree centigrade")
            break
    
        case "location":
            // Get the ETA
            var boo: Bool = true

            mapViewController.input = self.textView.text
            mapViewController.searchPlace(self.textView)
            bool = false
            
            // Get Review
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
                
                if boo {
                    self.textView.text = "There are 3 reviews, the positivePercentage is 0.67, negativePercentage is 0, and neutralPercentage is 0.33"
                    self.testToSpeech("There are 3 reviews, the positivePercentage is 0.67, negativePercentage is 0, and neutralPercentage is 0.33")
                    boo = false
                }
                
                self.textView.text = "There are 1 review, the positivePercentage is 1, negativePercentage is 0, and neutralPercentage is 0"
                self.testToSpeech("There are 1 review, the positivePercentage is 1, negativePercentage is 0, and neutralPercentage is 0")
            }
            
            break
            
        case "uber":
            self.textView.text = "You choose Uber, We We will redirect to the Uber"
            testToSpeech("You choose Uber, We will leave the app")
            break
        
        case "walk":
            // Open Apple Map
            self.textView.text = "You choose walk, We will redirect to the Apple app"
            testToSpeech("You choose walk, We will leave the app")
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
                let myLocation = CLLocationCoordinate2D(latitude: self.lat, longitude: self.lon)
                mapViewController.openInMapsTransit(coord: myLocation)
            }
            break
        
        case "public transportation":
            // Open Apple Map
            self.textView.text = "You choose bus, We will redirect to the Apple app"
            testToSpeech("You choose bus, We will leave the app")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
                let myLocation = CLLocationCoordinate2D(latitude: self.lat, longitude: self.lon)
                mapViewController.openInMapsTransit(coord: myLocation)
            }
            break
            
        default:
            self.textView.text = "Sorry, Please speak again!"
            testToSpeech("Sorry, Please speak again!")
            break
        }
    }
    
    
    
    /*
    These functions below are about the text to speech and speech to text
    */
    
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
    
    // Text to Speech
    func testToSpeech(_ outputText: String) {
        let utterance = AVSpeechUtterance(string: outputText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        let synVoice = AVSpeechSynthesizer()
        synVoice.speak(utterance)
    }
    
}
