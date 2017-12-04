//
//  CrimeKeyView.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 12/4/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit

class SafetyKeyView: UIView {

    
    class func instanceFromNib() -> SafetyKeyView {
        let currentView = UINib(nibName: "SafetyKeyView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SafetyKeyView
        currentView.layer.cornerRadius = currentView.frame.width/8
        return currentView
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
