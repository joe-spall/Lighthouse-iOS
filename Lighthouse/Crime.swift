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

struct Crime{
    let id:String
    let date:String
    let typeCrime:String
    let location:CLLocationCoordinate2D
}

func calculateThreatScore(userLocation: CLLocationCoordinate2D){
    
    
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
        guard let date = json["date"].string else {
            throw SerializationError.missing("date")
        }
        
        // Extract typeCrime
        guard let typeCrime = json["typeCrime"].string else {
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
        self.date = date
        self.typeCrime = typeCrime
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
    }
}
