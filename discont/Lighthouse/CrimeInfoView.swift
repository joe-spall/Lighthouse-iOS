//
//  CrimeCountView.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/12/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

@IBDesignable class CrimeInfoView: UIView {
    
    // Our custom view from the XIB file
    var view: UIView!
    
    @IBOutlet weak var crimeTypeLabel: UILabel!
    @IBOutlet weak var crimeDateLabel: UILabel!
    
    override init(frame: CGRect) {
        // 1. setup any properties here
        
        // 2. call super.init(frame:)
        super.init(frame: frame)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib() 
        
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "CrimeInfoView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func setAllCrimeInfo(currentCrime:Crime){
        setCrimeDateLabel(date: formatDate(inputDate: currentCrime.date))
        setCrimeTypeLabel(type: currentCrime.type)
    }
    
    func formatDate(inputDate:Date) -> String{
        let dateFormatter = DateFormatter()
        let dateFormat = UserDefaults.standard.string(forKey:"date_format")
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from:inputDate)
    }
    
    func setCrimeTypeLabel(type:String){
        crimeTypeLabel.text = type
    }
    
    func setCrimeDateLabel(date:String){
        crimeDateLabel.text = date
    }
    
    func getCrimeTypeLabel() -> String?{
        return crimeTypeLabel.text
    }
    
    func getCrimeDateLabel() -> String?{
        return crimeDateLabel.text
    }
    
}
