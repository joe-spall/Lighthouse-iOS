//
//  CrimeSlideTableViewCell.swift
//  Lighthouse
//
//  Created by Joseph Spall on 9/11/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

class CrimeSlideTableViewCell: UITableViewCell {

    @IBOutlet weak var crimeNameLabel: UILabel!
    @IBOutlet weak var dangerScoreLabel: UILabel!
    @IBOutlet weak var dangerSlider: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func dangerValueChanged(sender: UISlider) {
        let dangerValue = dangerSlider.value
        setDangerLabel(score: dangerValue)
        setDangerValue(score: dangerValue)
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
        let crimeKey = crimeNameLabel.text
        UserDefaults.standard.set(score,forKey: crimeKey!)
        
    }

}
