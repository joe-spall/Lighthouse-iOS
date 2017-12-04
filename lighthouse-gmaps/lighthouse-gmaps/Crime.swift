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
    let tag:String
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
        guard let id = json["_id"].string else {
            throw SerializationError.missing("_id")
        }
        
        // Extract date
        guard var dateString = json["Timestamp"].string else {
            throw SerializationError.missing("Timestamp")
        }
        
        // Extract type
        guard let type = json["Crime"].string else {
            throw SerializationError.missing("Crime")
        }
        
        guard let coords = json["Coordinates"].array else{
            throw SerializationError.missing("Coordinates")
            
        }
        
        var possibleTag = ""

        if(type == "HOMICIDE"){
            possibleTag = "homicide"
        }
        else if(type == "AGGRAVATED ASSAULT"){
            possibleTag = "assault"
        }
        else if(type == "RAPE"){
            possibleTag = "rape"
        }
        else if(type == "AUTO THEFT" || type == "BURGLARY FROM VEHICLE" || type == "LARCENY FROM VEHICLE"){
            possibleTag = "car_theft"
        }
        else{
            possibleTag = "ped_theft"
        }
        
        self.tag = possibleTag
        
        self.id = id
        let dateFormatHandle:DateFormatter = DateFormatter()
        dateFormatHandle.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateString = dateString.replacingOccurrences(of: "T", with: " ", options: NSString.CompareOptions.literal, range:nil)
        dateString = dateString.replacingOccurrences(of: ".000Z", with: "", options: NSString.CompareOptions.literal, range:nil)
        self.date = dateFormatHandle.date(from: dateString)!
        self.type = type
        self.location = CLLocationCoordinate2D(latitude: coords[1].double!, longitude: coords[0].double!)
        
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


