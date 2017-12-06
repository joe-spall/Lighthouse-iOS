//
//  CustomGMapsRender.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 11/8/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit

class MapClusterRender: GMUDefaultClusterRenderer{
    override func shouldRender(as cluster: GMUCluster, atZoom zoom: Float) -> Bool {
        return cluster.count >= 4 && zoom <= 21;
    }
}
