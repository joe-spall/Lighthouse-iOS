//
//  Route.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 11/5/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Route{
    let startLocation:CLLocationCoordinate2D
    let startAddress:String
    let endLocation:CLLocationCoordinate2D
    let endAddress:String
    let totalDuration:String
    let totalDistance:String
    let polylinePath:String
    let steps:[RouteStep]
}

extension Route {
    init(json: JSON) throws {
        // Extract starting latitude
        guard let startLat = json["legs"][0]["start_location"]["lat"].double else {
            throw SerializationError.missing("startLat")
        }
        
        // Extract starting longitude
        guard let startLng = json["legs"][0]["start_location"]["lng"].double else {
            throw SerializationError.missing("startLng")
        }
        
        guard let endLat = json["legs"][0]["end_location"]["lat"].double else {
            throw SerializationError.missing("endLat")
        }
        
        guard let endLng = json["legs"][0]["end_location"]["lng"].double else {
            throw SerializationError.missing("endLng")
        }
        
        guard let _startAddress = json["legs"][0]["start_address"].string else{
            throw SerializationError.missing("startAddress")
        }
        
        guard let _endAddress = json["legs"][0]["end_address"].string else{
            throw SerializationError.missing("endAddress")
        }
        
        guard let _totalDuration = json["legs"][0]["duration"]["text"].string else{
            throw SerializationError.missing("totalDuration")
        }
        
        guard let _totalDistance = json["legs"][0]["distance"]["text"].string else{
            throw SerializationError.missing("totalDistance")
        }
        
        guard let _polylinePath = json["overview_polyline"]["points"].string else{
            throw SerializationError.missing("polylinePath")
        }
        
        guard let _steps = json["legs"][0]["steps"].array else{
            throw SerializationError.missing("steps")
        }
        
        
        
        startLocation = CLLocationCoordinate2D(latitude: startLat, longitude: startLng)
        endLocation = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
        startAddress = _startAddress
        endAddress = _endAddress
        totalDuration = _totalDuration
        totalDistance = _totalDistance
        polylinePath = _polylinePath
        var _stepObjects:[RouteStep] = []
        for step in _steps {
            let newRouteStep = try RouteStep(json: step)
            _stepObjects.append(newRouteStep)
        }
        steps = _stepObjects
        

        

        
    }
}

