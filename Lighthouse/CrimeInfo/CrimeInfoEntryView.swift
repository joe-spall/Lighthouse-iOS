//
//  CrimeCountView.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/12/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

class CrimeInfoEntryView: UIView {
    
    @IBOutlet weak var crimeTypeLabel: UILabel!
    @IBOutlet weak var crimeDateLabel: UILabel!
    
    
    
   class func loadViewFromNib() -> UIView {
        return UINib(nibName: "CrimeInfoEntryView", bundle: nil).instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    
    
    func formatDate(inputDate:Date) -> String{
        let dateFormatter = DateFormatter()
        let dateFormat = UserDefaults.standard.string(forKey:"date_format")
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from:inputDate)
    }
    
    //Setters
    
    func setCrimeTypeLabel(type:String){
        crimeTypeLabel.text = type
    }
    
    func setCrimeDateLabel(date:String){
        crimeDateLabel.text = date
    }
    
    func setAllCrimeInfo(currentCrime:Crime){
        setCrimeDateLabel(date: formatDate(inputDate: currentCrime.date))
        setCrimeTypeLabel(type: currentCrime.type)
    }
    
    //Getters
    
    func getCrimeTypeLabel() -> String?{
        return crimeTypeLabel.text
    }
    
    func getCrimeDateLabel() -> String?{
        return crimeDateLabel.text
    }
    
    
    
}
