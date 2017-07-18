//
//  CrimeCountView.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/12/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

@IBDesignable class CrimeCountView: UIView {
    
    // Our custom view from the XIB file
    var view: UIView!
    

    @IBOutlet weak var crimeNumberLabel: UILabel!
    @IBOutlet weak var crimeLevelLabel: UILabel!
    
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
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red:0/255.0, green:0/255.0, blue:0/255.0, alpha: 1.0).cgColor
        view.layer.cornerRadius = 10
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "CrimeCountView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func setCrimeNumberLabel(number:String){
        crimeNumberLabel.text = number
    }
    
    func setCrimeLevelLabel(level:String){
        crimeLevelLabel.text = level
    }

}
