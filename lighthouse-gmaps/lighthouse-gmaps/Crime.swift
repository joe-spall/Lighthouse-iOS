//
//  Crime.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/5/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON
import GoogleMaps

let TIME_SINCE_WEIGHT:Double = 0.2
let TIME_SINCE_CONST:Double = -40
let DISTANCE_WEIGHT:Double = 0.1
let DISTANCE_CONST:Double = -1000
let TIME_OF_DAY_WEIGHT:Double = 0.1
let TIME_OF_DAY_CONST:Double = -2*pow(5,2)

struct Crime{
    let id:String
    let date:Date
    let type:String
    let location:CLLocationCoordinate2D
    
    
    func calculateSingleThreatScore(userLocation:CLLocationCoordinate2D, currentDate:Date, userValue:Double) -> Double{
        let timeSinceTotal:Double = TIME_SINCE_WEIGHT*pow(M_E,(Double(currentDate.timeIntervalSince(self.date))/2629743.83)/TIME_SINCE_CONST)
        let topOfExponent = pow(2,((Double(currentDate.timeIntervalSince(self.date))/3600000).truncatingRemainder(dividingBy: Double(12))-24))
        let timeOfDayTotal = TIME_OF_DAY_WEIGHT*pow(M_E,(topOfExponent/TIME_OF_DAY_CONST))
        var distanceTotal:Double = DISTANCE_WEIGHT;
        let distanceFromCrime = CLLocation.distance(from: self.location, to:userLocation)
        if(distanceFromCrime > 100){
            distanceTotal *= pow(M_E,(distanceFromCrime-100)/DISTANCE_CONST)
        }

        return (userValue*(timeSinceTotal+distanceTotal+timeOfDayTotal))
    }

}

enum SerializationError: Error {
    case missing(String)
}

extension Crime {
    init(json: JSON) throws {
        // Extract id
        guard let id = json["id"].string else {
            throw SerializationError.missing("id")
        }
        
        // Extract date
        guard let dateString = json["date"].string else {
            throw SerializationError.missing("date")
        }
        
        // Extract type
        guard let type = json["typeCrime"].string else {
            throw SerializationError.missing("typeCrime")
        }
        
        // Extract lat
        guard let lat = json["lat"].double else {
            throw SerializationError.missing("lat")
        }
        
        // Extract lng
        guard let lng = json["long"].double else {
            throw SerializationError.missing("lng")
        }
        
        self.id = id
        let dateFormatHandle:DateFormatter = DateFormatter()
        dateFormatHandle.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.date = dateFormatHandle.date(from: dateString)!
        self.type = type
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
    }
}

extension CLLocation {
    // In meteres
    class func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
}
