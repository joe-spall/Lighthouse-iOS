//
//  CrimeCluster.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 12/1/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import Foundation
class CrimeClusterItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var crime: Crime!
    
    init(crime: Crime) {
        self.position = crime.location
        self.crime = crime
    }
}
