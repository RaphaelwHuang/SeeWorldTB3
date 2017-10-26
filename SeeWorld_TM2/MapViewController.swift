//
//  MapViewController.swift
//  SeeWorld_TM2
//
//  Created by Raphael on 9/25/17.
//  Copyright © 2017 RaphaelwHuang. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import AVFoundation
import Speech


class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Your location
    var _lon: Double = 0.0
    var _lat: Double = 0.0
    
    // The search location
    var _lonEnd: Double = 0.0
    var _latEnd: Double = 0.0
    
    @IBOutlet weak var mapView: MKMapView!
   
    let locationManager = CLLocationManager()
    
    // Get value from the TextViewController
    var input: String = ""
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
    }
    
    // Text to Speech
    func testToSpeech(_ outputText: String) {
        let utterance = AVSpeechUtterance(string: outputText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        let synVoice = AVSpeechSynthesizer()
        synVoice.speak(utterance)
    }
    
    // Convert Func
    func convertTime (time: Double) -> String {
        var result:String
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        let minutes = Int((time / 60).truncatingRemainder(dividingBy: 60))
        let hours = Int(time / 3600)
        
        if (hours != 0) {
            result = "\(hours) hours, \(minutes) minutes and \(seconds) seconds."
        }
        else {
            result = "\(minutes) minutes and \(seconds) seconds."
        }
        
        return result
    }
    
    // Your location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations[0]
        
        
        _lon = Double(location.coordinate.longitude)
        _lat = Double(location.coordinate.latitude)
        
        
        // pass the value from map to text
        struct glovalVariable {
            static var userName = String();
        }
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        
        self.mapView.setRegion(region, animated: true)
        
        self.mapView.showsUserLocation = true
        
        
        //stop updating location to save battery life
        locationManager.stopUpdatingLocation()
    }
    
    // Search place
    func searchPlace(_ textView: UITextView)
    {
        //Perpare for search
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        dismiss(animated: true, completion: nil)

        //Create the search request
        let searchRequest = MKLocalSearchRequest()
        
        searchRequest.region = mapView.region
        searchRequest.naturalLanguageQuery = self.input
        
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil
            {
                print("ERROR")
            }
            else
            {
                //Remove annotations
                let annotations = self.mapView.annotations
                self.mapView.removeAnnotations(annotations)
                
                //Getting data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                self._latEnd = latitude!
                self._lonEnd = longitude!
                
                
//                //Create annotation
//                let objectAnnotation = MKPointAnnotation()
//                objectAnnotation.coordinate = CLLocation(latitude: self._latEnd,longitude: self._lonEnd).coordinate
//                objectAnnotation.title = self.input
//                self.mapView.addAnnotation(objectAnnotation)
//
//                //Zooming in on annotation
//                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(self._latEnd, self._lonEnd)
//
//                let span = MKCoordinateSpanMake(0.1, 0.1)
//                let region = MKCoordinateRegionMake(coordinate, span)
//                self.mapView.setRegion(region, animated: true)

                // Call ETA
                self.getETA(textView)
                self.updateLoc(latitude: self._latEnd, longitude: self._lonEnd)
            }
            
        }
    }
    // Update Loc
    func updateLoc(latitude: Double, longitude: Double) {
        //Create annotation
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = CLLocation(latitude: latitude,longitude: longitude).coordinate
        objectAnnotation.title = self.input
        self.mapView.addAnnotation(objectAnnotation)
        
        //Zooming in on annotation
        let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    // ETA func
    func getETA(_ textView: UITextView) {
        var byUber: String = ""
        var byPublic: String = ""
        var byWalk: String = ""
        
        // Uber
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self._lat, longitude: self._lon), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self._latEnd, longitude: self._lonEnd), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        var directions = MKDirections(request: request)
        directions.calculateETA { (response, error) in
            if error == nil {
                if let r = response {
                    byUber = self.convertTime(time: r.expectedTravelTime)
                    textView.text =  " If you would like to take Uber, it might take " + byUber
                    self.testToSpeech(" If you would like to take Uber, it might take " + byUber)
                }
            }
        }
        
        // Public transit
        let request2 = MKDirectionsRequest()
        request2.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self._lat, longitude: self._lon), addressDictionary: nil))
        request2.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self._latEnd, longitude: self._lonEnd), addressDictionary: nil))
        request2.requestsAlternateRoutes = true
        request2.transportType = .transit
        directions = MKDirections(request: request2)
        directions.calculateETA { (response, error) in
            if error == nil {
                if let r = response {
                    byPublic = self.convertTime(time: r.expectedTravelTime)
                    textView.text.append(" If you prefer to by public transit, it will take " + byPublic)
                    self.testToSpeech(" If you prefer to by public transit, it will take " + byPublic)
                }
            }
        }
        
        // Walk
        let request3 = MKDirectionsRequest()
        request3.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self._lat, longitude: self._lon), addressDictionary: nil))
        request3.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self._latEnd, longitude: self._lonEnd), addressDictionary: nil))
        request3.requestsAlternateRoutes = true
        request3.transportType = .walking
        directions = MKDirections(request: request3)
        directions.calculateETA { (response, error) in
            if error == nil {
                if let r = response {
                    byWalk = self.convertTime(time: r.expectedTravelTime)
                    textView.text.append( " If you choose walking to the destination, it will take " + byWalk)
                    self.testToSpeech(" If you choose walking to the destination, it will take " + byWalk)
                }
            }
        }
        
    }
    
    // Open Apple Map
    func openInMapsTransit(coord:CLLocationCoordinate2D) {
        let placemark = MKPlacemark(coordinate:coord, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeTransit]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
}

