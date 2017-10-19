//
//  DataModel.swift
//  SeeWorld_TM2
//
//  Created by Raphael on 9/28/17.
//  Copyright © 2017 RaphaelwHuang. All rights reserved.
//

import UIKit
import Foundation


class DataModel {
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    private let openWeatherMapAPIKey = "8d07dc0456656e99d50a7f6c050df180"
    
    
    func getWeather(city: String) {
        
        // This is a pretty simple networking task, so the shared session will do.
        let session = URLSession.shared
        
        let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)")!
        
        
        // The data task retrieves the data.
        let dataTask = session.dataTask(with: weatherRequestURL as URL) {
            (data : Data?, response : URLResponse?, error : Error?) in
            if let error = error {
                // Case 1: Error
                // We got some kind of error while trying to get data from the server.
                print("Error:\n\(error)")
            }
            else {
                let json = try? JSONSerialization.jsonObject(with: data!, options:  .mutableContainers) as? [String:AnyObject]
                
                print(json!!["main"]!["temp"])
                print(json!!["weather"]!)
                
            }
        }
        
        // The data task is set up...launch it!
        dataTask.resume()
    }
}
