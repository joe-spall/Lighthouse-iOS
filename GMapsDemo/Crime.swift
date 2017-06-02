//
//  Crime.swift
//  GMapsDemo
//
//  Created by Joseph Spall on 4/14/17.
//  Copyright © 2017 Appcoda. All rights reserved.
//

import UIKit


class Crime{
    
    var typeOfCrime:String!
    var dateOfCrime:String!
    var timeOfCrime:String!
    var latitude:Double!
    var longitude:Double!
    init(type:String, date:String, time:String, lat:Double, long:Double) {
        self.typeOfCrime = type
        self.dateOfCrime = date
        self.timeOfCrime = time
        self.latitude = lat
        self.longitude = long
    }
    
}

