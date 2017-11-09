//
//  ErrorHandling.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 11/9/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import Foundation

enum SerializationError: Error {
    case missing(String)
}

struct NetworkError: Error {
    enum Provider{
        case GoogleMaps
        case GooglePlaces
        case Lighthouse
    }
    let calledFunction:String
    let provider: Provider
    
}

struct apiError:Error{
    enum Provider{
        case GoogleMaps
        case GooglePlaces
        case Lighthouse
    }
}

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
