//
//  CrimeWeightSettingsTableViewCell.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 10/7/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit

class CrimeWeightTableViewCell: UITableViewCell {
    
    @IBOutlet weak var crimeNameLabel: UILabel!
    @IBOutlet weak var dangerScoreLabel: UILabel!
    @IBOutlet weak var dangerSlider: UISlider!
    var crimeTag:String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func dangerValueChanged(sender: UISlider) {
        setDangerLabel(score: dangerSlider.value)
    }
    
    @IBAction func dangerValueEnd(sender: UISlider){
        setDangerValue(score: dangerSlider.value)
    }
    
    func setDangerLabel(score: Float){
        var dangerLabelString = String(format: "%.2f",score)
        if(score == 1){
            dangerLabelString = "1"
        }
        else if(score == 0){
            dangerLabelString = "0"
        }
        dangerScoreLabel.text = dangerLabelString
        dangerScoreLabel.sizeToFit()
        dangerScoreLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        dangerScoreLabel.numberOfLines = 0
    }
    
    func setDangerValue(score: Float){
        if(crimeTag != ""){
            UserDefaults.standard.set(score,forKey: crimeTag)
        }
        
    }
    
}

