//
//  RouteStep.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 11/5/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import Foundation
import SwiftyJSON

struct RouteStep{
    let distanceStep:String
    let durationStep:String
    let startLocationStep:CLLocationCoordinate2D
    let endLocationStep:CLLocationCoordinate2D
    let instructStep:String
    let polylinePath:String
    var dangerLevel:Double = 0
    
}

extension RouteStep {
    init(json: JSON) throws {
        // Extract id
        guard let startLatStep = json["start_location"]["lat"].double else {
            throw SerializationError.missing("startLatStep")
        }
        
        guard let startLngStep = json["start_location"]["lng"].double else {
            throw SerializationError.missing("startLngStep")
        }
        
        guard let endLatStep = json["end_location"]["lat"].double else {
            throw SerializationError.missing("endLatStep")
        }
        
        guard let endLngStep = json["end_location"]["lng"].double else {
            throw SerializationError.missing("endLngStep")
        }
        
        guard let _durationStep = json["duration"]["text"].string else{
            throw SerializationError.missing("durationStep")
        }
        
        guard let _distanceStep = json["distance"]["text"].string else{
            throw SerializationError.missing("distanceStep")
        }
  
        guard let _instructStep = json["html_instructions"].string else{
            throw SerializationError.missing("instructStep")
        }
        
        guard let _polylinePath = json["polyline"]["points"].string else{
            throw SerializationError.missing("polylinePath")
        }
        
        startLocationStep = CLLocationCoordinate2D(latitude: startLatStep, longitude: startLngStep)
        endLocationStep = CLLocationCoordinate2D(latitude: endLatStep, longitude: endLngStep)
        durationStep = _durationStep
        distanceStep = _distanceStep
        instructStep = _instructStep.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
        polylinePath = _polylinePath
    
    }
}

